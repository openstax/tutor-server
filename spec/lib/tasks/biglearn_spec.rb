require 'rails_helper'
require 'database_cleaner'

RSpec.describe 'biglearn:initialize', type: :rake do
  include_context 'rake'

  before(:all) do
    DatabaseCleaner.clean_with :truncation

    # Each tasked TP has its own ecosystem and course and some number of students
    task_plan_1 = FactoryGirl.create :tasked_task_plan, number_of_students: 10
    task_plan_2 = FactoryGirl.create :tasked_task_plan, number_of_students: 5

    ecosystem_1 = Content::Ecosystem.new strategy: task_plan_1.ecosystem.wrap
    ecosystem_2 = Content::Ecosystem.new strategy: task_plan_2.ecosystem.wrap

    # Other courses using the same ecosystem as the task_plans above including updates
    course_1 = FactoryGirl.create :course_profile_course, offering: nil
    course_2 = FactoryGirl.create :course_profile_course, offering: nil
    course_3 = FactoryGirl.create :course_profile_course, offering: nil
    course_4 = FactoryGirl.create :course_profile_course, offering: nil

    AddEcosystemToCourse[ecosystem: ecosystem_1, course: course_1]
    AddEcosystemToCourse[ecosystem: ecosystem_2, course: course_2]
    AddEcosystemToCourse[ecosystem: ecosystem_1, course: course_3]
    AddEcosystemToCourse[ecosystem: ecosystem_2, course: course_3]
    AddEcosystemToCourse[ecosystem: ecosystem_1, course: course_4]
    AddEcosystemToCourse[ecosystem: ecosystem_2, course: course_4]

    # Courses without an ecosystem are not sent to Biglearn until they get one
    10.times { FactoryGirl.create :course_profile_course, offering: nil }
  end

  let(:result) { capture_stdout{ call } }

  it 'sends the correct number of records to Biglearn' do
    expect(OpenStax::Biglearn::Api).to receive(:create_ecosystem).twice
    expect(OpenStax::Biglearn::Api).to receive(:create_course).exactly(6).times
    expect(OpenStax::Biglearn::Api).to receive(:update_global_exercise_exclusions).exactly(6).times
    expect(OpenStax::Biglearn::Api).to receive(:update_course_exercise_exclusions).exactly(6).times
    expect(OpenStax::Biglearn::Api).to receive(:prepare_course_ecosystem).twice
    expect(OpenStax::Biglearn::Api).to receive(:update_course_ecosystems).once
    expect(OpenStax::Biglearn::Api).to receive(:update_rosters).once
    expect(OpenStax::Biglearn::Api).to receive(:create_update_assignments).twice

    result
  end

  it 'prints progress information' do
    expect(result).to include "Creating 2 ecosystems..\n"
    expect(result).to include "Creating 6 courses......\n"
    expect(result).to include "Creating 2 assignment plans..\n"
    expect(result).to include "Biglearn data transfer successful!\n"
  end
end
