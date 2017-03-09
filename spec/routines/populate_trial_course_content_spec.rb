require 'rails_helper'
require 'vcr_helper'

RSpec.describe PopulateTrialCourseContent, type: :routine, speed: :medium do

  before(:all) do
    ecosystem = VCR.use_cassette('PopulateTrialCourseContent/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    offering = FactoryGirl.create :catalog_offering, ecosystem: ecosystem.to_model

    @course = FactoryGirl.create :course_profile_course, offering: offering, is_trial: true

    @periods = 2.times.map { FactoryGirl.create :course_membership_period, course: @course }

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]
  end

  it 'creates the expected trial course content' do

    expect { result = described_class.call(course: @course) }
      .to change  { @course.students.reload.size }.by(6)
      .and change { Tasks::Models::TaskPlan.where(owner: @course).size }.by(4)
      .and change { Tasks::Models::TaskPlan.where(owner: @course).flat_map(&:tasks).size }.by(32)

    @periods.each do |period|
      student_roles = period.student_roles.sort_by(&:created_at)

      expect(student_roles.size).to eq 3

      # All roles except the last have completed everything
      student_roles[0..-2].each do |role|
        role.taskings.each do |tasking|
          tasking.task.task_steps.each { |task_step| expect(task_step).to be_completed }
        end
      end
    end

  end

end
