class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action.to_sym
    when :index
      !requestor.is_anonymous?
    when :read, :task_plans
      requestor.is_human? &&
      (UserIsCourseStudent[user: requestor, course: course] ||
       UserIsCourseTeacher[user: requestor, course: course])
    when :create_practice
      requestor.is_human? && course.active? &&
      (UserIsCourseStudent[user: requestor, course: course] ||
       UserIsCourseTeacher[user: requestor, course: course])
    when :export, :roster, :add_period, :update, :stats, :exercises
      requestor.is_human? && UserIsCourseTeacher[user: requestor, course: course]
    when :clone
      UserIsCourseTeacher[user: requestor, course: course]
    else
      false
    end
  end
end
