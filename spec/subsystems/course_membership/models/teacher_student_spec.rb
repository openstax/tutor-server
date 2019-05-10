require 'rails_helper'

RSpec.describe CourseMembership::Models::TeacherStudent, type: :model do
  subject(:teacher_student) { FactoryBot.create :course_membership_teacher_student }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:period) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_uniqueness_of(:role) }

  [:username, :first_name, :last_name, :full_name].each do |method|
    it { is_expected.to delegate_method(method).to(:role) }
  end
end
