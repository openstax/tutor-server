require 'rails_helper'

describe UserIsCourseTeacher, type: :routine do

  context "when the user is not a teacher for the given course" do
    it "returns false" do
      target_user = FactoryGirl.create(:user)

      target_student_role = Entity::Role.create!
      target_teacher_role = Entity::Role.create!

      other_user = FactoryGirl.create(:user)

      other_teacher_role  = Entity::Role.create!

      target_course       = Entity::Course.create!
      target_period       = CreatePeriod.call(course: target_course).period

      other_course        = Entity::Course.create!

      Role::AddUserRole.call(user: target_user, role: target_teacher_role)
      Role::AddUserRole.call(user: target_user, role: target_student_role)
      Role::AddUserRole.call(user: other_user,  role: other_teacher_role)

      ## Make the target user a teacher of another course
      CourseMembership::AddTeacher.call(course: other_course, role: target_teacher_role)
      ## Make the target user a student in the target course
      CourseMembership::AddStudent.call(period: target_period, role: target_student_role)
      ## Make another user a teacher of the target course
      CourseMembership::AddTeacher.call(course: target_course, role: other_teacher_role)

      ## Perform test
      result = UserIsCourseTeacher.call(user: target_user, course: target_course)
      expect(result).to be_falsey
    end
  end

  context "when the user a teacher for the given course" do
    it "returns true" do
      ## Make the target user a teacher for the target course
      target_user = FactoryGirl.create(:user)

      target_teacher_role = Entity::Role.create!

      target_course       = Entity::Course.create!
      Role::AddUserRole.call(user: target_user, role: target_teacher_role)
      CourseMembership::AddTeacher.call(course: target_course, role: target_teacher_role)

      ## Perform test
      result = UserIsCourseTeacher.call(user: target_user, course: target_course)
      expect(result).to be_truthy
    end
  end
end
