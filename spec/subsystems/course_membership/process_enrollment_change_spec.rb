require 'rails_helper'

RSpec.describe CourseMembership::ProcessEnrollmentChange, type: :routine, speed: :medium do
  let(:course_1)  { FactoryBot.create :course_profile_course }
  let(:course_2)  { FactoryBot.create :course_profile_course }
  let(:course_3)  { FactoryBot.create :course_profile_course }

  let(:period_1)  { FactoryBot.create :course_membership_period, course: course_1 }
  let(:period_2)  { FactoryBot.create :course_membership_period, course: course_1 }
  let(:period_3)  { FactoryBot.create :course_membership_period, course: course_2 }
  let(:period_4)  { FactoryBot.create :course_membership_period, course: course_3 }

  let(:book)      { FactoryBot.create :content_book }

  let(:ecosystem) { book.ecosystem }

  let(:user)      { FactoryBot.create :user_profile }

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

      before(:each)           { enrollment_change.approve_by(user).save! }

      it 'processes an approved EnrollmentChange' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true
      end

      it 'sets the student_identifier if given' do
        sid = 'N0B0DY'
        result = nil
        expect{ result = described_class.call(args.merge(student_identifier: sid)) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true

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
        expect(result.outputs.enrollment_change.processed?).to eq true

        enrollment_change_2.reload
        enrollment_change_3.reload
        enrollment_change_4.reload
        enrollment_change_5.reload

        expect(enrollment_change_2.rejected?).to eq true
        expect(enrollment_change_3.rejected?).to eq true
        expect(enrollment_change_4.rejected?).to eq true
        expect(enrollment_change_5.rejected?).to eq true
      end
    end

    context 'same course' do
      let(:enrollment_change) do
        CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_2.enrollment_code
        ]
      end

      before(:each)           do
        AddUserAsPeriodStudent[user: user, period: period_1]

        enrollment_change.approve_by(user).save!

        expect(enrollment_change.enrollment).not_to be_nil
      end

      it 'processes an approved EnrollmentChange' do
        result = nil
        expect{ result = described_class.call(args) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true
      end

      it 'sets the student_identifier if given' do
        sid = 'N0B0DY'
        result = nil
        expect{ result = described_class.call(args.merge(student_identifier: sid)) }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true

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
        expect(result.outputs.enrollment_change.processed?).to eq true

        enrollment_change_2.reload

        expect(enrollment_change_2.rejected?).to eq true
      end

      it 'returns an error if the target course has already ended' do
        current_time = Time.current
        course_1.starts_at = current_time.last_month
        course_1.ends_at = current_time.yesterday
        course_1.save!
        enrollment_change.reload

        result = nil
        expect do
          result = described_class.call(args)
        end.not_to change{ CourseMembership::Models::Enrollment.count }
        expect(enrollment_change.errors.full_messages).to(
          include('Period belongs to a course that has already ended')
        )
        enrollment_change.reload
        expect(enrollment_change.approved?).to eq true
      end
    end

    context 'different course' do
      let!(:student)           { AddUserAsPeriodStudent[user: user, period: period_1].student }

      let(:enrollment_change)  do
        CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_3.enrollment_code
        ]
      end

      before(:each)            { enrollment_change.approve_by(user).save! }

      it 'processes an approved EnrollmentChange' do
        result = nil
        expect { result = described_class.call(args) }
          .to change { CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true
      end

      it 'sets the student_identifier if given' do
        sid = 'N0B0DY'
        result = nil
        expect { result = described_class.call(args.merge(student_identifier: sid)) }
          .to change { CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true

        student = CourseMembership::Models::Enrollment.order(:created_at).last.student
        expect(student.student_identifier).to eq sid
      end

      it 'rejects other pending EnrollmentChanges for the same user' do
        enrollment_change_2 = CourseMembership::CreateEnrollmentChange[
          user: user, enrollment_code: period_4.enrollment_code
        ]

        result = nil
        expect { result = described_class.call(args) }
          .to change { CourseMembership::Models::Enrollment.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true

        enrollment_change_2.reload

        expect(enrollment_change_2.rejected?).to eq true
      end

      it 'creates new role and student objects for the new course' do
        old_roles = user.roles.to_a
        result = nil
        expect { result = described_class.call(args) }
          .to change { CourseMembership::Models::Student.count }.by(1)
        expect(result.errors).to be_empty
        expect(result.outputs.enrollment_change.processed?).to eq true
        expect(student.reload.course).to eq course_1
        new_role = (user.reload.roles - old_roles).first
        expect(new_role.student.course).to eq course_2
      end

      it 'returns an error if the target course has already ended' do
        current_time = Time.current
        course_2.starts_at = current_time.last_month
        course_2.ends_at = current_time.yesterday
        course_2.save!
        enrollment_change.reload

        result = nil
        expect { result = described_class.call(args) }
          .not_to change { CourseMembership::Models::Enrollment.count }
        expect(enrollment_change.errors.full_messages).to(
          include('Period belongs to a course that has already ended')
        )
        enrollment_change.reload
        expect(enrollment_change.approved?).to eq true
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
      expect { result = described_class.call(args) }
        .not_to change { CourseMembership::Models::Enrollment.count }
      enrollment_change.reload
      expect(enrollment_change.pending?).to eq true
    end

    it 'returns an error if the EnrollmentChange has been rejected' do
      enrollment_change.update_attribute(
        :status, CourseMembership::Models::EnrollmentChange.statuses[:rejected]
      )

      result = nil
      expect { result = described_class.call(args) }
        .not_to change { CourseMembership::Models::Enrollment.count }
      expect(result.errors).not_to be_empty
      enrollment_change.reload
      expect(enrollment_change.rejected?).to eq true
    end
  end
end
