require 'rails_helper'

RSpec.describe CourseMembership::CreateEnrollmentChange, type: :routine, speed: :medium do
  let(:course_1)  { FactoryBot.create :course_profile_course, :without_ecosystem }
  let(:course_2)  { FactoryBot.create :course_profile_course, :without_ecosystem }

  let(:period_1)  { FactoryBot.create :course_membership_period, course: course_1 }
  let(:period_2)  { FactoryBot.create :course_membership_period, course: course_1 }
  let(:period_3)  { FactoryBot.create :course_membership_period, course: course_2 }

  let(:book)      { FactoryBot.create :content_book }

  let(:ecosystem) { Content::Ecosystem.new(strategy: book.ecosystem.wrap) }

  let(:user)      do
    profile = FactoryBot.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let(:args)      { { user: user, enrollment_code: period_1.enrollment_code } }

  before do
    AddEcosystemToCourse[course: course_1, ecosystem: ecosystem]
    AddEcosystemToCourse[course: course_2, ecosystem: ecosystem]
  end

  it "returns invalid_enrollment_code error if the given enrollment code is invalid" do
    result = nil
    expect{ result = described_class.call(user: user, enrollment_code: '1nv4l1d!') }
      .not_to change{ CourseMembership::Models::EnrollmentChange.count }
    expect(result.errors.first.code).to eq :invalid_enrollment_code
  end

  it "returns preview_course error if the associated period's course is a preview course" do
    course_1.update_attribute :is_preview, true
    result = nil
    expect{ result = described_class.call(args) }
      .not_to change{ CourseMembership::Models::EnrollmentChange.count }
    expect(result.errors.first.code).to eq :preview_course
  end

  it "returns course_ended error if the associated period's course has ended" do
    course_1.update_attribute :ends_at, Time.current
    result = nil
    expect{ result = described_class.call(args) }
      .not_to change{ CourseMembership::Models::EnrollmentChange.count }
    expect(result.errors.first.code).to eq :course_ended
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

      context 'when other period is archived' do
          before{ period_2.to_model.destroy }

          it 'does not mention previous period' do
              result = nil
              expect{ result = described_class.call(args) }
                  .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
              expect(result.errors).to be_empty
              expect(result.outputs.enrollment_change.from_period).to be_nil
              expect(result.outputs.enrollment_change.status).to eq :pending
              expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
          end
      end

      it 'creates an EnrollmentChange with a from_period' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.from_period.to_model).to eq period_2
        expect(result.outputs.enrollment_change.status).to eq :pending
        expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
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

      it 'creates an EnrollmentChange' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.from_period).to be_nil
        expect(result.outputs.enrollment_change.status).to eq :pending
        expect(result.outputs.enrollment_change.enrollee_approved_at).to be_nil
      end
    end

    context 'in a different CC course' do
      let!(:role) do
        AddUserAsPeriodStudent[user: user, period: period_3]
      end

      before      do
        course_1.update_attribute :is_concept_coach, true
        course_2.update_attribute :is_concept_coach, true
      end

      it 'creates an EnrollmentChange' do
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
