require 'rails_helper'

RSpec.describe CourseMembership::EnrollmentChange, type: :wrapper do
  let(:course)                { FactoryGirl.create :course_profile_course }
  let(:period_1)              { FactoryGirl.create :course_membership_period, course: course }
  let(:period_2)              { FactoryGirl.create :course_membership_period, course: course }

  let(:user)                  { FactoryGirl.create :user }

  let!(:role)                 do
    AddUserAsPeriodStudent[user: user, period: period_1]
  end

  subject(:enrollment_change) do
    CourseMembership::CreateEnrollmentChange[user: user, enrollment_code: period_2.enrollment_code]
  end

  it 'exposes id, user, from_period, to_period, pending?, approved?, rejected? and to_model' do
    [:id, :user, :from_period, :to_period,
     :pending?, :approved?, :rejected?, :to_model].each do |method_name|
      expect(enrollment_change).to respond_to(method_name)
    end

    expect(enrollment_change.id).to be_a Integer
    expect(enrollment_change.user).to eq user
    expect(enrollment_change.from_period.to_model).to eq period_1
    expect(enrollment_change.to_period.to_model).to eq period_2
    expect(enrollment_change.status).to eq :pending
    expect(enrollment_change.pending?).to eq true
    expect(enrollment_change.approved?).to eq false
    expect(enrollment_change.rejected?).to eq false
    expect(enrollment_change.to_model).to be_a CourseMembership::Models::EnrollmentChange
  end
end
