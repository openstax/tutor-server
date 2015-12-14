require 'rails_helper'

describe CourseMembership::ProcessEnrollmentChange, type: :routine do
  let!(:period)            { CreatePeriod.call(course: Entity::Course.create!).period }
  let!(:period_2)          { CreatePeriod.call(course: period.course).period }

  let!(:user)              do
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let!(:enrollment_change) { CourseMembership::CreateEnrollmentChange.call(user: user, period: period).enrollement_change }

  let!(:args)              { { enrollment_change: enrollment_change } }

  context 'approved enrollment_change' do
    before(:each) { enrollment_change.to_model.approve_by(user).save! }

    it 'processes an approved EnrollmentChange' do
      result = nil
      expect{ result = described_class.call(args) }
        .to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.enrollment_change.status).to eq :processed
    end

    it 'sets the student_identifier if given' do
      sid = 'N0B0DY'
      result = nil
      expect{ result = described_class.call(args.merge(student_identifier: sid)) }
        .to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.enrollment_change.status).to eq :processed

      student = CourseMembership::Models::Enrollment.order(:created_at).last.student
      expect(student.student_identifier).to eq sid
    end

    it 'rejects other pending EnrollmentChanges for the same user and course' do
      enrollment_change_2 = CourseMembership::CreateEnrollmentChange.call(user: user, period: period)
      enrollment_change_3 = CourseMembership::CreateEnrollmentChange.call(user: user, period: period_2)

      result = nil
      expect{ result = described_class.call(args) }
        .to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.enrollment_change.status).to eq :processed

      enrollment_change_2.to_model.reload
      enrollment_change_3.to_model.reload

      expect(enrollment_change_2.status).to eq :rejected
      expect(enrollment_change_3.status).to eq :rejected
    end
  end

  context 'not approved enrollment_change' do
    it 'returns an error if the EnrollmentChange is pending' do
      result = nil
      expect{ result = described_class.call(args) }
        .not_to change{ CourseMembership::Models::Enrollment.count }
      enrollment_change.to_model.reload
      expect(enrollment_change.status).to eq :pending
    end

    it 'returns an error if the EnrollmentChange has been rejected' do
      enrollment_change.to_model.update_attribute(
        :status, CourseMembership::Models::EnrollmentChange.statuses[:rejected]
      )

      result = nil
      expect{ result = described_class.call(args) }
        .not_to change{ CourseMembership::Models::Enrollment.count }
      expect(result.errors).not_to be_empty
      enrollment_change.to_model.reload
      expect(enrollment_change.status).to eq :rejected
    end
  end
end
