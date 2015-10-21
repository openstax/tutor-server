require 'rails_helper'

RSpec.describe CourseMembership::Models::Period, type: :model do
  subject(:period) { CreatePeriod[course: Entity::Course.create!].to_model }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to have_many(:teachers) }
  it { is_expected.to have_many(:teacher_roles) }

  it { is_expected.to have_many(:enrollments) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:entity_course_id) }

  it 'cannot be deleted if it has any active students' do
    student_user = FactoryGirl.create(:user)
    AddUserAsPeriodStudent[period: period, user: student_user]
    expect { period.destroy }.not_to change{CourseMembership::Models::Period.count}
    expect(period.errors).not_to be_empty
    period.enrollments.each{ |en| en.student.inactivate.save! }
    expect { period.destroy }.to change{CourseMembership::Models::Period.count}.by(-1)
  end
end
