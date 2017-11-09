require 'rails_helper'

RSpec.describe UserIsCourseTeacher, type: :routine do

  context "when the user is not a teacher for the given course" do
    it "returns false" do
      target_user         = FactoryBot.create :user

      target_student_role = FactoryBot.create :entity_role
      target_teacher_role = FactoryBot.create :entity_role

      other_user          = FactoryBot.create :user

      other_teacher_role  = FactoryBot.create :entity_role

      target_course       = FactoryBot.create :course_profile_course
      target_period       = FactoryBot.create :course_membership_period, course: target_course

      other_course        = FactoryBot.create :course_profile_course

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
      expect(result.errors).to be_empty
      expect(result.outputs.user_is_course_teacher).to be_falsey
    end
  end

  context "when the user a teacher for the given course" do
    it "returns true" do
      ## Make the target user a teacher for the target course
      target_user         = FactoryBot.create(:user)

      target_teacher_role = FactoryBot.create :entity_role

      target_course       = FactoryBot.create :course_profile_course
      Role::AddUserRole.call(user: target_user, role: target_teacher_role)
      CourseMembership::AddTeacher.call(course: target_course, role: target_teacher_role)

      ## Perform test
      result = UserIsCourseTeacher.call(user: target_user, course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.user_is_course_teacher).to be_truthy
    end
  end
end
