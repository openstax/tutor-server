require 'rails_helper'

RSpec.describe CourseMembership::Models::Period, type: :model do
  subject(:period) { CreatePeriod[course: Entity::Course.create!] }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to have_many(:teachers) }
  it { is_expected.to have_many(:teacher_roles) }

  it { is_expected.to have_many(:students) }
  it { is_expected.to have_many(:student_roles) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:entity_course_id) }

  it 'cannot be deleted if it has any students' do
    student_profile = FactoryGirl.create(:user_profile)
    AddUserAsPeriodStudent[period: period, user: student_profile.entity_user]
    expect { period.destroy }.not_to change(CourseMembership::Models::Period.count)
    expect(period.errors).not_to be_empty
    period.students.destroy_all
    expect { period.destroy }.to change(CourseMembership::Models::Period.count).by(-1)
  end
end
