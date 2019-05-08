require 'rails_helper'

RSpec.describe CourseMembership::Models::Teacher, type: :model do
  subject(:teacher) { FactoryBot.create :course_membership_teacher }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:role) }

  it { is_expected.to validate_uniqueness_of(:role) }

  [:username, :first_name, :last_name, :full_name].each do |method|
    it { is_expected.to delegate_method(method).to(:role) }
  end
end
