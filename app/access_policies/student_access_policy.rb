class StudentAccessPolicy
  def self.action_allowed?(action, requestor, student)
    case action
    when :create, :update, :destroy
      requestor.is_human? && 
      UserIsCourseTeacher[user: requestor.user, course: student.course]
    else
      false
    end
  end
end
