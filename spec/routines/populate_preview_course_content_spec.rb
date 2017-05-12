require 'rails_helper'
require 'vcr_helper'

RSpec.describe PopulatePreviewCourseContent, type: :routine, speed: :medium do

  before(:all) do
    ecosystem = VCR.use_cassette('PopulatePreviewCourseContent/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    offering = FactoryGirl.create :catalog_offering, ecosystem: ecosystem.to_model

    @course = FactoryGirl.create :course_profile_course, offering: offering, is_preview: true

    FactoryGirl.create :course_membership_period, course: @course

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]
  end

  context 'when the course has less than 2 periods' do
    it 'creates new periods until the course has at least 2' +
       ' and populates the expected preview course content' do
      expect { result = described_class.call(course: @course) }
        .to change { @course.students.reload.size }.by(6)
        .and change { @course.periods.reload.size }.to(2)
        .and change { Tasks::Models::TaskPlan.where(owner: @course).size }.by(4)
        .and change { Tasks::Models::TaskPlan.where(owner: @course).flat_map(&:tasks).size }.by(32)

      # all task plans should be marked as "is_preview"
      Tasks::Models::TaskPlan.where(owner: @course).each { |tp| expect(tp.is_preview).to eq(true) }

      @course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        expect(student_roles.size).to eq 3

        # All roles except the last have completed everything
        student_roles[0..-2].each do |role|
          role.taskings.each do |tasking|
            tasking.task.task_steps.each do |task_step|
              expect(task_step).to be_completed
            end
          end
        end
      end
    end
  end

  context 'when the course has 2 or more periods' do
    before(:all) do
      DatabaseCleaner.start

      FactoryGirl.create :course_membership_period, course: @course
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'does not create any new periods and populates the expected preview course content' do
      expect { result = described_class.call(course: @course) }
        .to change { @course.students.reload.size }.by(6)
        .and not_change { @course.periods.reload.size }
        .and change { Tasks::Models::TaskPlan.where(owner: @course).size }.by(4)
        .and change { Tasks::Models::TaskPlan.where(owner: @course).flat_map(&:tasks).size }.by(32)

      @course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        expect(student_roles.size).to eq 3

        # All roles except the last have completed everything
        student_roles[0..-2].each do |role|
          role.taskings.each do |tasking|
            tasking.task.task_steps.each do |task_step|
              expect(task_step).to be_completed
            end
          end
        end
      end
    end
  end

end
