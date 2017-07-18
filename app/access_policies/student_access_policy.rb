class StudentAccessPolicy
  def self.action_allowed?(action, requestor, student)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :create, :update, :destroy
      UserIsCourseTeacher[user: requestor, course: student.course]
    when :refund
      student.role.role_user.user_profile_id == requestor.id
    else
      false
    end
  end
end
