class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action
    when :index
      !requestor.is_anonymous?
    when :read, :task_plans
      requestor.is_human? && \
      (UserIsCourseStudent[user: requestor.entity_user, course: course] || \
       UserIsCourseTeacher[user: requestor.entity_user, course: course])
    when :export, :roster
      requestor.is_human? && UserIsCourseTeacher[user: requestor.entity_user, course: course]
    else
      false
    end
  end
end
