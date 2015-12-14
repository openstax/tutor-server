class StudentAccessPolicy
  def self.action_allowed?(action, requestor, student)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :create, :update, :destroy
      UserIsCourseTeacher.call(user: requestor, course: student.course)
    else
      false
    end
  end
end
