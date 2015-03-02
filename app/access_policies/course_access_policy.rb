class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action
    when :readings
      debugger
      requestor.is_human? # && 
      # Domain::UserIsCourseTeacher.call(user: requestor.human_user, 
      #                                  course: course)
    else
      false
    end
  end
end