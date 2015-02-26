require 'rails_helper'

describe Domain::UserIsCourseTeacher do

  context "when the user is not a teacher for the given course" do
    it "returns false" do
      ## Make the target user a teacher of another course
      target_user         = Entity::CreateUser.call.outputs.user
      target_teacher_role = Entity::CreateRole.call.outputs.role
      other_course        = Entity::CreateCourse.call.outputs.course
      Role::AddUserRole.call(user: target_user, role: target_teacher_role)
      CourseMembership::AddTeacher.call(course: other_course, role: target_teacher_role)

      ## Make the target user a student in the target course
      target_course       = Entity::CreateCourse.call.outputs.course
      target_student_role = Entity::CreateRole.call.outputs.role
      Role::AddUserRole.call(user: target_user, role: target_student_role)
      CourseMembership::AddStudent.call(course: other_course, role: target_student_role)

      ## Make another user a teacher of the target course
      other_user         = Entity::CreateUser.call.outputs.user
      other_teacher_role = Entity::CreateRole.call.outputs.role
      Role::AddUserRole.call(user: other_user,  role: other_teacher_role)
      CourseMembership::AddTeacher.call(course: target_course, role: other_teacher_role)

      ## Perform test
      result = Domain::UserIsCourseTeacher.call(user: target_user, course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.user_is_course_teacher).to be_falsey
    end
  end
  context "when the user is not a teacher for the given course" do
    it "returns true" do
      ## Make the target user a teacher for the target course
      target_user         = Entity::CreateUser.call.outputs.user
      target_teacher_role = Entity::CreateRole.call.outputs.role
      target_course       = Entity::CreateCourse.call.outputs.course
      Role::AddUserRole.call(user: target_user, role: target_teacher_role)
      CourseMembership::AddTeacher.call(course: target_course, role: target_teacher_role)

      ## Perform test
      result = Domain::UserIsCourseTeacher.call(user: target_user, course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.user_is_course_teacher).to be_truthy
    end
  end
end
