require 'rails_helper'

RSpec.describe CourseMembership::ProcessEnrollmentChange, type: :routine do
  let(:course_1)  { FactoryGirl.create :course_profile_course }
  let(:course_2)  { FactoryGirl.create :course_profile_course }
  let(:course_3)  { FactoryGirl.create :course_profile_course }

  let(:period_1)  { FactoryGirl.create :course_membership_period, course: course_1 }
  let(:period_2)  { FactoryGirl.create :course_membership_period, course: course_1 }
  let(:period_3)  { FactoryGirl.create :course_membership_period, course: course_2 }
  let(:period_4)  { FactoryGirl.create :course_membership_period, course: course_3 }

  let(:book)      { FactoryGirl.create :content_book }

  let(:ecosystem) { Content::Ecosystem.new(strategy: book.ecosystem.wrap) }

  let(:user)      do
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let(:args)      { { enrollment_change: enrollment_change } }

  before          do
    AddEcosystemToCourse[course: course_1, ecosystem: ecosystem]
    AddEcosystemToCourse[course: course_2, ecosystem: ecosystem]
  end

  context 'approved enrollment_change' do
    context 'no existing courses' do
      let(:enrollment_change) do
        CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_1.enrollment_code
        ]
      end

      before(:each)           { enrollment_change.to_model.approve_by(user).save! }

      it 'processes an approved EnrollmentChange' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed
      end

      it 'sets the student_identifier if given' do
        sid = 'N0B0DY'
        result = nil
        expect{ result = described_class.call(args.merge(student_identifier: sid)) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed

        student = CourseMembership::Models::Enrollment.order(:created_at).last.student
        expect(student.student_identifier).to eq sid
      end

      it 'rejects other pending EnrollmentChanges for the same user' do
        enrollment_change_2 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_1.enrollment_code
        ]
        enrollment_change_3 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_2.enrollment_code
        ]
        enrollment_change_4 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_3.enrollment_code
        ]
        enrollment_change_5 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_4.enrollment_code
        ]

        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed

        enrollment_change_2.to_model.reload
        enrollment_change_3.to_model.reload
        enrollment_change_4.to_model.reload
        enrollment_change_5.to_model.reload

        expect(enrollment_change_2.status).to eq :rejected
        expect(enrollment_change_3.status).to eq :rejected
        expect(enrollment_change_4.status).to eq :rejected
        expect(enrollment_change_5.status).to eq :rejected
      end
    end

    context 'same course' do
      let(:student)           { AddUserAsPeriodStudent[user: user, period: period_1].student }

      let(:enrollment_change) do
        CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_2.enrollment_code
        ]
      end

      before(:each)           { enrollment_change.to_model.approve_by(user).save! }

      it 'processes an approved EnrollmentChange' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed
      end

      it 'sets the student_identifier if given' do
        sid = 'N0B0DY'
        result = nil
        expect{ result = described_class.call(args.merge(student_identifier: sid)) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed

        student = CourseMembership::Models::Enrollment.order(:created_at).last.student
        expect(student.student_identifier).to eq sid
      end

      it 'rejects other pending EnrollmentChanges for the same user' do
        enrollment_change_2 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_4.enrollment_code
        ]

        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed

        enrollment_change_2.to_model.reload

        expect(enrollment_change_2.status).to eq :rejected
      end

      it 'returns an error if the target course has already ended' do
        current_time = Time.current
        course_1.starts_at = current_time.last_month
        course_1.ends_at = current_time.yesterday
        course_1.save!
        enrollment_change.to_model.reload

        result = nil
        expect do
          result = described_class.call(args)
        end.not_to change{ CourseMembership::Models::Enrollment.count }
        expect(enrollment_change.to_model.errors.full_messages).to(
          include('Period belongs to a course that has already ended')
        )
        enrollment_change.to_model.reload
        expect(enrollment_change.status).to eq :approved
      end
    end

    context 'different course' do
      let!(:student)           { AddUserAsPeriodStudent[user: user, period: period_1].student }

      let(:enrollment_change)  do
        CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_3.enrollment_code
        ]
      end

      before(:each)            { enrollment_change.to_model.approve_by(user).save! }

      it 'processes an approved EnrollmentChange' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed
      end

      it 'sets the student_identifier if given' do
        sid = 'N0B0DY'
        result = nil
        expect{ result = described_class.call(args.merge(student_identifier: sid)) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed

        student = CourseMembership::Models::Enrollment.order(:created_at).last.student
        expect(student.student_identifier).to eq sid
      end

      it 'rejects other pending EnrollmentChanges for the same user' do
        enrollment_change_2 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_4.enrollment_code
        ]

        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed

        enrollment_change_2.to_model.reload

        expect(enrollment_change_2.status).to eq :rejected
      end

      it 'creates new role and student objects for the new course' do
        old_roles = user.to_model.roles.to_a
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Student.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.status).to eq :processed
        expect(student.reload.course).to eq course_1
        new_role = (user.to_model.reload.roles - old_roles).first
        expect(new_role.student.course).to eq course_2
      end

      it 'returns an error if the target course has already ended' do
        current_time = Time.current
        course_2.starts_at = current_time.last_month
        course_2.ends_at = current_time.yesterday
        course_2.save!
        enrollment_change.to_model.reload

        result = nil
        expect{ result = described_class.call(args) }
          .not_to change{ CourseMembership::Models::Enrollment.count }
        expect(enrollment_change.to_model.errors.full_messages).to(
          include('Period belongs to a course that has already ended')
        )
        enrollment_change.to_model.reload
        expect(enrollment_change.status).to eq :approved
      end
    end
  end

  context 'not approved enrollment_change' do
    let(:enrollment_change) do
      CourseMembership::CreateEnrollmentChange[
        user: user, enrollment_code: period_3.enrollment_code
      ]
    end

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
