require 'rails_helper'

describe Domain::AddUserAsCourseTeacher do
  context "when the given user is not a teacher in the given course" do
    it "returns the user's new teacher role" do
      user   = EntitySs::CreateUser.call.outputs.user
      course = EntitySs::CreateCourse.call.outputs.course

      result = Domain::AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil
    end
  end
  context "when the given user is a teacher in the given course" do
    it "has errors" do
      user   = EntitySs::CreateUser.call.outputs.user
      course = EntitySs::CreateCourse.call.outputs.course

      result = Domain::AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil

      result = Domain::AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to_not be_empty
    end
  end
end
