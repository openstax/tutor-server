require 'rails_helper'

describe "domain: course roles" do

  context "adding teachers to courses" do
    let(:target_user)   { Entity::User.create! }
    let(:target_course) { Domain::CreateCourse.call.outputs.course }
    context "when a user is not a teacher of a course" do
      it "the user can be made a course teacher" do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty

        result = Domain::UserIsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy
      end
    end
    context "when the user is a teacher of a course" do
      before(:each) do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
      end
      it "the user cannot be (re)made a course teacher" do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to_not be_empty

        result = Domain::UserIsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy
      end
    end
    context "courses with multiple teachers" do
      let(:target_user1)  { Entity::User.create! }
      let(:target_user2)  { Entity::User.create! }
      let(:target_course) { Domain::CreateCourse.call.outputs.course }
      it "are allowed" do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user1, course: target_course)
        expect(result.errors).to be_empty

        result = Domain::AddUserAsCourseTeacher.call(user: target_user2, course: target_course)
        expect(result.errors).to be_empty

        result = Domain::UserIsCourseTeacher.call(user: target_user1, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy

        result = Domain::UserIsCourseTeacher.call(user: target_user2, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy
      end
    end
  end

  context "adding students to courses" do
    let(:target_user)   { Entity::User.create! }
    let(:target_course) { Domain::CreateCourse.call.outputs.course }
    context "when a user is not a teacher of a course" do
      context "and the user is not a student in the course" do
        it "the user can be added as a course student" do
          result = Domain::AddUserAsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty

          result = Domain::UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.user_is_course_student).to be_truthy
        end
      end
      context "and the user is already a student in the course" do
        before(:each) do
          result = Domain::AddUserAsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
        end
        it "the user cannot be (re)added as a course student" do
          result = Domain::AddUserAsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to_not be_empty

          result = Domain::UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.user_is_course_student).to be_truthy
        end
      end
    end
    context "when a user is a teacher of a course" do
      before(:each) do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
      end
      context "and the user is not already a student in the course" do
        it "the user can be added as a course student" do
          result = Domain::AddUserAsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty

          result = Domain::UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.user_is_course_student).to be_truthy
        end
      end
      context "and the user is already a student in the course" do
        before(:each) do
          result = Domain::AddUserAsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          @previous_student_role = result.outputs.role
          expect(@previous_student_role).to_not be_nil
        end
        let(:previous_student_role) { @previous_student_role }

        it "the user can be added as a course student" do
          result = Domain::AddUserAsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.role).to_not be_nil
          expect(result.outputs.role).to_not eq(previous_student_role)

          result = Domain::UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.user_is_course_student).to be_truthy
        end
      end
    end
  end
end
