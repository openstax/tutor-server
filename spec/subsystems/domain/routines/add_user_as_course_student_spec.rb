require 'rails_helper'

describe Domain::AddUserAsCourseStudent do
  context "when the given user is not a teacher of the course" do
    let(:user)   { Entity::CreateUser.call.outputs.user }
    let(:course) { Entity::CreateCourse.call.outputs.course }

    context "and not already a student of the course" do
      it "succeeds and returns the user's new student role" do
        result = Domain::AddUserAsCourseStudent.call(user: user, course: course)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
      end
    end
    context "and already a student in the given course" do
      before(:each) do
        result = Domain::AddUserAsCourseStudent.call(user: user, course: course)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
      end
      it "has errors" do
        result = Domain::AddUserAsCourseStudent.call(user: user, course: course)
        expect(result.errors).to_not be_empty
      end
    end
  end
  context "when the given user is a teacher in the given course" do
    let(:user)   { Entity::CreateUser.call.outputs.user }
    let(:course) { Entity::CreateCourse.call.outputs.course }
    before(:each) do
      result = Domain::AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil
    end
    context "and not already a student of the course" do
      it "succeeds and returns the user's new student role" do
        result = Domain::AddUserAsCourseStudent.call(user: user, course: course)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
      end
    end
    context "and already a student in the given course" do
      before(:each) do
        result = Domain::AddUserAsCourseStudent.call(user: user, course: course)
        expect(result.errors).to be_empty
        @previous_student_role = result.outputs.role
        expect(@previous_student_role).to_not be_nil
      end
      let(:previous_student_role) { @previous_student_role }

      it "succeeds and returns the user's new student role" do
        result = Domain::AddUserAsCourseStudent.call(user: user, course: course)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
        expect(result.outputs.role).to_not eq(previous_student_role)
      end
    end
  end
end
