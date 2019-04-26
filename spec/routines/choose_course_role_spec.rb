require 'rails_helper'

RSpec.describe ChooseCourseRole, type: :routine do

  let(:teacher)    { FactoryBot.create :user }
  let(:student)    { FactoryBot.create :user }
  let(:interloper) { FactoryBot.create :user }
  let(:course)     { FactoryBot.create :course_profile_course }
  let(:period)     { FactoryBot.create :course_membership_period, course: course }

  let!(:teacher_role)         { AddUserAsCourseTeacher[user: teacher, course: course] }
  let!(:student_role)         { AddUserAsPeriodStudent[user: student, period: period] }
  let!(:teacher_student_role) do
    FactoryBot.create(:course_membership_teacher_student, period: period).role
  end

  context "when the user is both a teacher and a student" do

    let(:user) { FactoryBot.create(:user) }
    let!(:user_teacher_role) { AddUserAsCourseTeacher[user: user, course: course] }
    let!(:user_student_role) { AddUserAsPeriodStudent[user: user, period: period] }

    context "and a role is not given" do
      context "and allowed_role_types is not given" do
        subject {
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            role: nil
          )
        }
        it "returns the user's teacher role" do
          expect(subject.outputs.role).to eq(user_teacher_role)
        end
      end

      context "and allowed_role_types: :teacher" do
        subject {
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            role: nil,
            allowed_role_types: :teacher
          )
        }
        it "returns the user's teacher role" do
          expect(subject.outputs.role).to eq(user_teacher_role)
        end
      end

      context "and allowed_role_types: :student" do
        subject {
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            role: nil,
            allowed_role_types: :student
          )
        }
        it "returns the user's student role" do
          expect(subject.outputs.role).to eq(user_student_role)
        end
      end
    end
  end

  context "when a role is provided" do
    context "and the user has it" do
      subject { ChooseCourseRole.call(user: student, course: course, role: student_role) }
      it "returns the user's role" do
        expect(subject.outputs.role).to eq(student_role)
      end
    end

    context "and the user lacks it" do
      subject(:result) {
        ChooseCourseRole.call(user: student, course: course, role: teacher_role)
      }

      context "errors" do
        subject { result.errors }
        it { should_not be_empty }
        it { expect(subject.first.code).to eq(:user_not_in_course_with_required_role) }
      end

      context "output" do
        subject{ result.outputs.role }
        it { should be_nil }
      end
    end

  end

  context "when a role is not given" do

    context "and the user does not have any roles on the course" do
      subject(:result) { ChooseCourseRole.call(user: interloper, course: course, role: nil) }

      context "errors" do
        subject { result.errors }
        it { should_not be_empty }
        it { expect(subject.first.code).to eq(:user_not_in_course_with_required_role) }
      end

      context "output" do
        subject{ result.outputs.role }
        it { should be_nil }
      end
    end

    context "and the user has a single role" do
      subject(:result) { ChooseCourseRole.call(user: teacher, course: course, role: nil) }

      context "errors" do
        subject { result.errors }
        it { should be_empty }
      end

      context "output" do
        subject{ result.outputs.role }
        it { should eq(teacher_role) }
      end
    end

    context "and the user has a multiple roles" do
      let!(:student_role_1) { AddUserAsPeriodStudent[user: teacher, period: period] }
      let!(:student_role_2) do
        # Bypass AddUserAsPeriodStudent's error checking
        role = FactoryBot.create :entity_role, role_type: :student
        Role::AddUserRole[user: teacher, role: role]
        CourseMembership::AddStudent[period: period, role: role]
      end
      let(:role_type)     { nil }
      let(:args)          do
        { user: teacher, course: course, role: nil }.tap do |args|
          args[:allowed_role_types] = role_type unless role_type.nil?
        end
      end
      subject(:found)     { ChooseCourseRole.call(args).outputs.role }

      it "returns the oldest role" do
        expect(found).to eq(teacher_role)
      end

      context "and a student role is requested" do
        let(:role_type) { :student }

        it "returns the oldest student role" do
          expect(found).to eq student_role_1
        end
      end
    end

  end
end
