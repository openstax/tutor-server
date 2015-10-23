require 'rails_helper'

describe CourseMembership::CreateEnrollmentChange, type: :routine do
  let!(:period_1) { CreatePeriod[course: Entity::Course.create!] }
  let!(:period_2) { CreatePeriod[course: period_1.course] }

  let!(:user)     do
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let!(:args)     { { user: user, period: period_1 } }

  context 'with no existing enrollments' do
    it 'creates an EnrollmentChange' do
      result = nil
      expect{ result = described_class.call(args) }
        .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs.enrollment_change.status).to eq :pending
      expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
    end

    it 'automatically approves the EnrollmentChange if it doesn\'t require approval' do
      expect_any_instance_of(CourseMembership::ApproveEnrollmentChange).to(
        receive(:call).once.and_call_original
      )

      result = nil
      expect{ result = described_class.call(args.merge(requires_enrollee_approval: false)) }
        .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs.enrollment_change.status).to eq :approved
      expect(result.outputs.enrollment_change.enrollee_approved_at).not_to be_nil
    end
  end

  context 'with existing enrollments' do
    let!(:role)       do
      AddUserAsPeriodStudent[user: user, period: period_2]
    end

    let!(:enrollment) { role.student.latest_enrollment }

    it 'creates an EnrollmentChange' do
      result = nil
      expect{ result = described_class.call(args) }
        .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs.enrollment_change.status).to eq :pending
      expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
    end

    it 'automatically approves the EnrollmentChange if it doesn\'t require approval' do
      expect_any_instance_of(CourseMembership::ApproveEnrollmentChange).to(
        receive(:call).once.and_call_original
      )

      result = nil
      expect{ result = described_class.call(args.merge(requires_enrollee_approval: false)) }
        .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs.enrollment_change.status).to eq :approved
      expect(result.outputs.enrollment_change.enrollee_approved_at).not_to be_nil
    end

    it 'returns an error if the user has multiple student roles in the course' do
      second_role = Role::CreateUserRole[user, :student]
      CourseMembership::AddStudent[period: period_1, role: second_role]

      result = nil
      expect{ result = described_class.call(args.merge(period: period_2)) }
        .not_to change{ CourseMembership::Models::EnrollmentChange.count }
      expect(result.errors).to be_present
      expect(result.errors.first.code).to eq :multiple_roles
    end

    it 'returns an error if the user has been dropped from the course' do
      user.to_model.roles.first.student.inactivate.save!

      result = nil
      expect{ result = described_class.call(args) }
        .not_to change{ CourseMembership::Models::EnrollmentChange.count }
      expect(result.errors).to be_present
      expect(result.errors.first.code).to eq :dropped_student
    end
  end
end
