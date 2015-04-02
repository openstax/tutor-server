require 'rails_helper'

describe Domain::GetCourseUserRole do

  let(:teacher){ Entity::CreateUser.call.outputs.user }
  let(:student){ Entity::CreateUser.call.outputs.user }

  let(:interloper){ Entity::CreateUser.call.outputs.user }

  let(:course){ Entity::CreateCourse.call.outputs.course }

  let!(:teacher_role){
    role=Entity::CreateRole.call(:teacher).outputs.role
    Role::AddUserRole[user: teacher, role: role]
    CourseMembership::AddTeacher[course: course, role: role]
    role
  }

  let!(:student_role){
    role=Entity::CreateRole.call(:student).outputs.role
    Role::AddUserRole[user: student, role: role]
    # CourseMembership::AddStudent routine also creates a user?
    CourseMembership::Models::Student.create(entity_course_id: course.id, entity_role_id: role.id)
    role
  }


  context "when a role is provided" do

    context "and the user has it" do
      subject { Domain::VerifyCourseRole.call(user: student, course: course, role: student_role) }
      it "returns the user's role" do
        expect(subject.outputs.role).to eq(student_role)
      end
    end

    context "and the user lacks it" do
      subject(:result) {
        Domain::VerifyCourseRole.call(user: student, course: course, role: teacher_role)
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

  end

  context "when a role is not given" do
    context "and the user does not have any roles on the course" do
      subject(:result) {
        Domain::VerifyCourseRole.call(user: interloper, course: course)
      }

      describe "errors" do
        subject { result.errors }
        it { should_not be_empty }
        it { expect(subject.first.code).to eq(:invalid_user) }
      end

      describe "output" do
        subject{ result.outputs.role }
        it { should be_nil }
      end
    end


    context "and the user has a single role" do
      subject(:result) {
        Domain::VerifyCourseRole.call(user: teacher, course: course)
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
        let(:role_type){ :any }
        subject(:found) {
          role=Entity::CreateRole.call(:student).outputs.role
          Role::AddUserRole[user: teacher, role: role]
          CourseMembership::Models::Student.create(entity_course_id: course.id, entity_role_id: role.id)
          Domain::VerifyCourseRole.call(
            user: teacher, course: course, role_type: role_type
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
        role=Entity::CreateRole.call(:student).outputs.role
        Role::AddUserRole[user: student, role: role]
        CourseMembership::Models::Student.create!(entity_course_id: course.id, entity_role_id: role.id)

        errors = Domain::VerifyCourseRole.call(user: student, course: course).errors
        expect(errors).not_to be_empty
        expect(errors.first.code).to eq(:multiple_roles)
      end

    end

  end
end
