require 'rails_helper'

RSpec.describe ChooseCourseRole, type: :routine do

  let(:teacher)       { FactoryBot.create :user }
  let(:student)       { FactoryBot.create :user }
  let(:interloper)    { FactoryBot.create :user }
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }

  let!(:teacher_role) {
    AddUserAsCourseTeacher[user: teacher, course: course]
  }

  let!(:student_role) {
    AddUserAsPeriodStudent[user: student, period: period]
  }

  context "when the user is both a teacher and a student" do

    let(:user) { FactoryBot.create(:user) }

    let!(:user_teacher_role) {
      AddUserAsCourseTeacher[user: user, course: course]
    }

    let!(:user_student_role) {
      AddUserAsPeriodStudent[user: user, period: period]
    }

    context "and a role id is not given" do
      context "and allowed_role_type: :any" do
        subject {
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            allowed_role_type: :any
          )
        }
        it "returns the user's teacher role" do
          expect(subject.outputs.role).to eq(user_teacher_role)
        end
      end
      context "and allowed_role_type: :teacher" do
        subject {
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            allowed_role_type: :teacher
          )
        }
        it "returns the user's teacher role" do
          expect(subject.outputs.role).to eq(user_teacher_role)
        end
      end
      context "and allowed_role_type: :student" do
        subject {
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            allowed_role_type: :student
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
      subject { ChooseCourseRole.call(user: student, course: course, role_id: student_role.id) }
      it "returns the user's role" do
        expect(subject.outputs.role).to eq(student_role)
      end
    end

    context "and the user lacks it" do
      subject(:result) {
        ChooseCourseRole.call(user: student, course: course, role_id: teacher_role.id)
      }

      describe "errors" do
        subject { result.errors }
        it { should_not be_empty }
        it { expect(subject.first.code).to eq(:invalid_role) }
      end

      describe "output" do
        subject{ result.outputs.role }
        it { should be_nil }
      end
    end

    context "and the role is a course student and the user is a teacher" do
      context "and the student is active" do
        subject {
          ChooseCourseRole.call(user: teacher, course: course, role_id: student_role.id)
        }

        it "returns the provided role" do
          expect(subject.outputs.role).to eq(student_role)
        end
      end

      context "and the student is inactive" do
        subject do
          student_role.student.destroy
          ChooseCourseRole.call(user: teacher, course: course, role_id: student_role.id)
        end

        it "returns the provided role" do
          expect(subject.outputs.role).to eq(student_role)
        end
      end
    end

  end

  context "when a role is not given" do

    context "and the user does not have any roles on the course" do
      subject(:result) {
        ChooseCourseRole.call(user: interloper, course: course)
      }

      describe "errors" do
        subject { result.errors }
        it { should_not be_empty }
        it { expect(subject.first.code).to eq(:user_not_in_course_with_required_role) }
      end

      describe "output" do
        subject{ result.outputs.role }
        it { should be_nil }
      end
    end

    context "and the user has a single role" do
      subject(:result) {
        ChooseCourseRole.call(user: teacher, course: course)
      }

      describe "errors" do
        subject { result.errors }
        it { should be_empty }
      end

      describe "output" do
        subject{ result.outputs.role }
        it { should eq(teacher_role) }
      end
    end

    context "and the user has a multiple roles" do
      context "when one is a teacher" do
        let(:role_type) { :any }
        subject(:found) {
          role = AddUserAsPeriodStudent[user: teacher, period: period]
          ChooseCourseRole.call(
            user: teacher, course: course, allowed_role_type: role_type
          ).outputs.role
        }

        it "returns the teacher role if one is present" do
          expect(found).to eq(teacher_role)
        end

        context "will only return the type that :ensure_type is set to" do
          let(:role_type){ :student }
          it { expect(found.role_type).to eq("student") }
        end
      end

      it "fails with an error if one is not a teacher" do
        # Bypass AddUserAsPeriodStudent's error checking
        role = FactoryBot.create :entity_role, role_type: :student
        Role::AddUserRole[user: student, role: role]
        CourseMembership::AddStudent[period: period, role: role]

        errors = ChooseCourseRole.call(user: student, course: course).errors
        expect(errors).not_to be_empty
        expect(errors.first.code).to eq(:multiple_roles)
      end
    end

  end
end
