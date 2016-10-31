class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    return false if requestor.is_anonymous? || !requestor.is_human?

    case action.to_sym
    when :index
      true
    when :read
      UserIsCourseStudent[user: requestor, course: course] ||
      UserIsCourseTeacher[user: requestor, course: course]
    when :create_practice
      course.active? &&
      UserIsCourseStudent[user: requestor, course: course] ||
      UserIsCourseTeacher[user: requestor, course: course]
    when :read_task_plans, :export, :roster, :add_period, :update, :stats, :exercises
      UserIsCourseTeacher[user: requestor, course: course]
    when :create
      requestor.account.confirmed_faculty?
    when :clone
      UserIsCourseTeacher[user: requestor, course: course] &&
      course.offering.is_available
    else
      false
    end
  end
end
