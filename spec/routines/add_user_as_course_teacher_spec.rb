require 'rails_helper'

describe AddUserAsCourseTeacher, type: :routine do
  context "when the given user is not a teacher in the given course" do
    it "returns the user's new teacher role" do
      user = FactoryGirl.create(:user)
      course = Entity::Course.create!

      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.role).to_not be_nil
    end
  end
  context "when the given user is a teacher in the given course" do
    it "has errors" do
      user = FactoryGirl.create(:user)
      course = Entity::Course.create!

      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.role).to_not be_nil

      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to_not be_empty
    end
  end
end
