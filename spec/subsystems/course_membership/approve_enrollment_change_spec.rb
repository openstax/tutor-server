require 'rails_helper'

describe CourseMembership::ApproveEnrollmentChange, type: :routine do
  let!(:period)            { CreatePeriod[course: Entity::Course.create!] }
  let!(:period_2)          { CreatePeriod[course: period.course] }

  let!(:user)              do
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let!(:enrollment_change) { CourseMembership::CreateEnrollmentChange[user: user, period: period] }

  let!(:args)              { { enrollment_change: enrollment_change, approved_by: user } }

  it 'approves an EnrollmentChange' do
    result = nil
    expect{ result = described_class.call(args) }
      .to change{ CourseMembership::Models::Enrollment.count }.by(1)
    expect(result.errors).to be_empty
    expect(result.outputs.enrollment_change.status).to eq 'approved'
    expect(result.outputs.enrollment_change.enrollee_approved_at).to be_present
  end

  it 'rejects other pending EnrollmentChanges for the same user and course' do
    enrollment_change_2 = CourseMembership::CreateEnrollmentChange[user: user, period: period]
    enrollment_change_3 = CourseMembership::CreateEnrollmentChange[user: user, period: period_2]

    result = nil
    expect{ result = described_class.call(args) }
      .to change{ CourseMembership::Models::Enrollment.count }.by(1)
    expect(result.errors).to be_empty
    expect(result.outputs.enrollment_change.status).to eq 'approved'
    expect(result.outputs.enrollment_change.enrollee_approved_at).to be_present

    expect(enrollment_change_2.reload.status).to eq 'rejected'
    expect(enrollment_change_3.reload.status).to eq 'rejected'
  end

  it 'returns an error if the EnrollmentChange has already been approved' do
    described_class.call(args)

    result = nil
    expect{ result = described_class.call(args) }
      .not_to change{ CourseMembership::Models::Enrollment.count }
    expect(result.errors).not_to be_empty
    expect(enrollment_change.reload.status).to eq 'approved'
    expect(enrollment_change.enrollee_approved_at).to be_present
  end

  it 'returns an error if the EnrollmentChange has already been rejected' do
    enrollment_change.update_attribute(
      :status, CourseMembership::Models::EnrollmentChange.statuses[:rejected]
    )

    result = nil
    expect{ result = described_class.call(args) }
      .not_to change{ CourseMembership::Models::Enrollment.count }
    expect(result.errors).not_to be_empty
    expect(enrollment_change.reload.status).to eq 'rejected'
    expect(enrollment_change.enrollee_approved_at).to be_nil
  end
end
