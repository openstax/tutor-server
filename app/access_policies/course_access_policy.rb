class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action
    when :readings
      requestor.is_human?
    else
      false
    end
  end
end
