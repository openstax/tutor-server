require 'rails_helper'

RSpec.describe CourseMembership::Models::Period, type: :model do
  subject!(:period) { FactoryBot.create :course_membership_period }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to have_many(:teachers) }
  it { is_expected.to have_many(:teacher_roles) }

  it { is_expected.to have_many(:enrollments) }

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:course_profile_course_id) }

  it 'can be deleted and restored even if it has active students' do
    student_user = FactoryBot.create(:user_profile)
    AddUserAsPeriodStudent[period: period, user: student_user]

    expect(UserIsCourseStudent[user: student_user, course: period.course]).to eq true

    expect { period.destroy! }.to change { period.reload.archived? }.from(false).to(true)
    expect(period.errors).to be_empty

    expect(UserIsCourseStudent[user: student_user, course: period.course]).to eq false

    expect { period.restore!(recursive: true) }.to(
      change{ period.reload.archived? }.from(true).to(false)
    )
    expect(period.errors).to be_empty

    expect(UserIsCourseStudent[user: student_user, course: period.course]).to eq true
  end

  it 'does not collide in name with deleted periods' do
    expect { period.destroy! }.to change { period.reload.archived? }.from(false).to(true)
    new_period = FactoryBot.create :course_membership_period, course: period.course,
                                                               name: period.name
    expect(new_period).to be_valid
    expect(new_period).to be_persisted
  end

  it 'validates format of default times' do
    period.default_open_time = '16:32'
    expect(period).to be_valid

    period.default_open_time = '16:'
    expect(period).not_to be_valid

    period.default_open_time = '24:00'
    expect(period).not_to be_valid

    period.default_open_time = '23:60'
    expect(period).not_to be_valid
  end

end
