require 'rails_helper'

RSpec.describe Tasks::Models::CourseAssistant, type: :model do
  subject { FactoryGirl.create :tasks_course_assistant }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:assistant) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:assistant) }
  it { is_expected.to validate_presence_of(:tasks_task_plan_type) }

  it { is_expected.to(
    validate_uniqueness_of(:tasks_task_plan_type).scoped_to(:course_profile_course_id)
  ) }
end
