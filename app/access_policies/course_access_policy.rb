class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action
    when :readings
      requestor.is_human?
    when :exercises, :export
      UserIsCourseTeacher[user: requestor.entity_user, course: course]
    else
      false
    end
  end
end
