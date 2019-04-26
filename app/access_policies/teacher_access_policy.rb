class TeacherAccessPolicy
  def self.action_allowed?(action, requestor, teacher)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :show
      teacher.role.user_profile_id == requestor.id && !teacher.deleted?
    when :destroy
      UserIsCourseTeacher[user: requestor, course: teacher.course]
    else
      false
    end
  end
end
