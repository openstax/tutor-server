require 'rails_helper'
require 'vcr_helper'

RSpec.describe PopulatePreviewCourseContent, type: :routine, speed: :medium do
  before(:all) do
    ecosystem = VCR.use_cassette('PopulatePreviewCourseContent/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    offering = FactoryBot.create :catalog_offering, ecosystem: ecosystem

    @course = FactoryBot.create :course_profile_course, :with_grading_templates,
                                                        offering: offering, is_preview: true
  end

  before do
    expect(WorkPreviewCourseTasks).to receive(:perform_later).with(course: @course).once

    @course.reload
  end

  context 'when the course has no periods' do
    it 'creates a new period and populates the expected preview course content' do
      # 4 tasks for each of the 6 students + 1 preview role
      expect { result = described_class.call(course: @course) }
        .to  change { @course.students.reload.size }.by(6)
        .and change { @course.periods.reload.size }.from(0).to(1)
        .and change { Tasks::Models::TaskPlan.where(course: @course).size }.by(4)
        .and change { Tasks::Models::TaskPlan.where(course: @course).flat_map(&:tasks).size }.by(24)

      # all task plans should be marked as "is_preview"
      Tasks::Models::TaskPlan.where(course: @course).each { |tp| expect(tp.is_preview).to eq(true) }

      @course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        expect(student_roles.size).to eq 6

        student_roles.each do |role|
          role.taskings.each do |tasking|
            task = tasking.task

            expect(task.opens_at).to be_within(1).of task.due_at - 7.days
            expect(task.closes_at).to be_within(1.day).of @course.ends_at - 1.day

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

      FactoryBot.create :course_membership_period, course: @course
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'does not create any new periods and populates the expected preview course content' do
      # 4 tasks for each of the 6 students + 1 preview role
      expect do
        result = described_class.call(course: @course)
      end.to not_change { @course.periods.count }
         .and change { @course.students.count }.by(6)
         .and change { Tasks::Models::TaskPlan.where(course: @course).size }.by(4)
         .and(
           change { Tasks::Models::TaskPlan.where(course: @course).flat_map(&:tasks).size }.by(24)
         )

      @course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        expect(student_roles.size).to eq 6

        student_roles.each do |role|
          role.taskings.each do |tasking|
            task = tasking.task

            expect(task.opens_at).to be_within(1).of task.due_at - 7.days
            expect(task.closes_at).to be_within(1.day).of @course.ends_at - 1.day

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
