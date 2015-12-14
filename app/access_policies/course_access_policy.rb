class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action.to_sym
    when :index
      !requestor.is_anonymous?
    when :read, :task_plans
      requestor.is_human? && \
      (UserIsCourseStudent.call(user: requestor, course: course) || \
       UserIsCourseTeacher.call(user: requestor, course: course))
    when :export, :roster, :add_period, :update, :stats
      requestor.is_human? && UserIsCourseTeacher.call(user: requestor, course: course)
    else
      false
    end
  end
end
