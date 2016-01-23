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
    expect{ period.destroy }.not_to change{CourseMembership::Models::Period.count}
    expect(period.errors).not_to be_empty
    period.enrollments.each{ |en| en.student.destroy }
    expect{ period.destroy }.to change{CourseMembership::Models::Period.count}.by(-1)
  end

  it 'does not collide in name with deleted periods' do
    period.enrollments.each{ |en| en.student.destroy }
    expect{ period.destroy }.to change{CourseMembership::Models::Period.count}.by(-1)
    CreatePeriod[course: Entity::Course.create!, name: period.name]
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
