class TeacherAccessPolicy
  def self.action_allowed?(action, requestor, teacher)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :destroy
      UserIsCourseTeacher.call(user: requestor, course: teacher.course)
    else
      false
    end
  end
end
