require 'rails_helper'

describe CourseMembership::CreateEnrollmentChange, type: :routine do
  let(:course_1)  { FactoryGirl.create :entity_course }
  let(:course_2)  { FactoryGirl.create :entity_course }
  let(:course_3)  { FactoryGirl.create :entity_course }

  let(:period_1)  { CreatePeriod[course: course_1] }
  let(:period_2)  { CreatePeriod[course: course_1] }
  let(:period_3)  { CreatePeriod[course: course_2] }
  let(:period_4)  { CreatePeriod[course: course_3] }

  let(:book)      { FactoryGirl.create :content_book }

  let(:ecosystem) { Content::Ecosystem.new(strategy: book.ecosystem.wrap) }

  let(:user)     do
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let(:args)     { { user: user, period: period_1 } }

  before do
    AddEcosystemToCourse[course: course_1, ecosystem: ecosystem]
    AddEcosystemToCourse[course: course_2, ecosystem: ecosystem]
  end

  context 'with no existing enrollments' do
    it 'creates an EnrollmentChange with a nil from_period' do
      result = nil
      expect{ result = described_class.call(args) }
        .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs.enrollment_change.from_period).to be_nil
      expect(result.outputs.enrollment_change.status).to eq :pending
      expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
    end
  end

  context 'with existing enrollments' do
    context 'in the same course' do
      let!(:role)       do
        AddUserAsPeriodStudent[user: user, period: period_2]
      end

      let(:enrollment) { role.student.latest_enrollment }

      it 'creates an EnrollmentChange with a from_period' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.from_period).to eq period_2
        expect(result.outputs.enrollment_change.status).to eq :pending
        expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
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
        user.to_model.roles.first.student.destroy

        result = nil
        expect{ result = described_class.call(args) }
          .not_to change{ CourseMembership::Models::EnrollmentChange.count }
        expect(result.errors).to be_present
        expect(result.errors.first.code).to eq :dropped_student
      end
    end

    context 'in a different Tutor course' do
      let!(:role) do
        AddUserAsPeriodStudent[user: user, period: period_3]
      end

      it 'creates an EnrollmentChange with a nil from_period' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.from_period).to be_nil
        expect(result.outputs.enrollment_change.status).to eq :pending
        expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
      end
    end

    context 'in a different CC course with the same book' do
      let!(:role) do
        AddUserAsPeriodStudent[user: user, period: period_3]
      end

      before      do
        course_1.profile.update_attribute :is_concept_coach, true
        course_2.profile.update_attribute :is_concept_coach, true
      end

      it 'returns an error message' do
        result = nil
        expect{ result = described_class.call(args) }
          .not_to change{ CourseMembership::Models::EnrollmentChange.count }
        expect(result.errors.first.code).to eq :concept_coach_conflict
        expect(result.errors.first.message).to(
          eq 'You are already enrolled in a Concept Coach course for this book. ' +
             'If you are trying to transfer between courses, ' +
             'please contact customer service for assistance.'
        )
      end
    end

    context 'in a different CC course with a different book' do
      let!(:role)       do
        AddUserAsPeriodStudent[user: user, period: period_4]
      end

      before      do
        course_1.profile.update_attribute :is_concept_coach, true
        course_3.profile.update_attribute :is_concept_coach, true
      end

      it 'creates an EnrollmentChange with a nil from_period' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.from_period).to be_nil
        expect(result.outputs.enrollment_change.status).to eq :pending
        expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
      end
    end
  end
end
