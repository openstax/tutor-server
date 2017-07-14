require 'rails_helper'
require 'vcr_helper'

RSpec.describe PopulatePreviewCourseContent, type: :routine, speed: :medium do

  before(:all) do
    ecosystem = VCR.use_cassette('PopulatePreviewCourseContent/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    offering = FactoryGirl.create :catalog_offering, ecosystem: ecosystem.to_model

    @course = FactoryGirl.create :course_profile_course, offering: offering, is_preview: true

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]
  end

  let(:expected_opens_at) do
    [ @course.time_zone.to_tz.now.monday - 2.weeks, @course.starts_at ].max
  end

  before { expect(WorkPreviewCourseTasks).to receive(:perform_later).with(course: @course).once }

  context 'when the course has no periods' do
    it 'creates a new period and populates the expected preview course content' do
      # 4 tasks for each of the 6 students + 1 preview role
      expect { result = described_class.call(course: @course) }
        .to  change { @course.students.reload.size }.by(6)
        .and change { @course.periods.reload.size }.from(0).to(1)
        .and change { Tasks::Models::TaskPlan.where(owner: @course).size }.by(4)
        .and change { Tasks::Models::TaskPlan.where(owner: @course).flat_map(&:tasks).size }.by(28)

      # all task plans should be marked as "is_preview"
      Tasks::Models::TaskPlan.where(owner: @course).each { |tp| expect(tp.is_preview).to eq(true) }

      @course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        expect(student_roles.size).to eq 6

        # All roles except the third and sixth have completed everything
        (student_roles[0..1] + student_roles[3..4]).each do |role|
          role.taskings.each do |tasking|
            task = tasking.task

            expect(task.opens_at).to be_within(1.hour).of expected_opens_at

            task.task_steps.each do |task_step|
              expect(task_step).not_to be_completed

              next unless task_step.exercise?

              expect(task_step.tasked.free_response).to be_nil
            end
          end
        end
      end
    end
  end

  context 'when the course has a period' do
    before(:all) do
      DatabaseCleaner.start

      FactoryGirl.create :course_membership_period, course: @course
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'does not create any new periods and populates the expected preview course content' do
      # 4 tasks for each of the 6 students + 1 preview role
      expect { result = described_class.call(course: @course) }
        .to change { @course.students.reload.size }.by(6)
        .and not_change { @course.periods.reload.size }
        .and change { Tasks::Models::TaskPlan.where(owner: @course).size }.by(4)
        .and change { Tasks::Models::TaskPlan.where(owner: @course).flat_map(&:tasks).size }.by(28)

      @course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        expect(student_roles.size).to eq 6

        # All roles except the third and sixth have completed everything
        (student_roles[0..1] + student_roles[3..4]).each do |role|
          role.taskings.each do |tasking|
            task = tasking.task

            expect(task.opens_at).to be_within(1.hour).of expected_opens_at

            task.task_steps.each do |task_step|
              expect(task_step).not_to be_completed

              next unless task_step.exercise?

              expect(task_step.tasked.free_response).to be_nil
            end
          end
        end
      end
    end
  end

end
