class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action
    when :index
      !requestor.is_anonymous?
    when :read, :task_plans
      requestor.is_human? && \
      (UserIsCourseStudent[user: requestor.user, course: course] || \
       UserIsCourseTeacher[user: requestor.user, course: course])
    when :export, :roster
      requestor.is_human? && UserIsCourseTeacher[user: requestor.user, course: course]
    else
      false
    end
  end
end
