class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    return false if requestor.is_anonymous? || !requestor.is_human?

    case action.to_sym
    when :index
      true
    when :read, :create_practice, :performance
      UserIsCourseStudent[user: requestor, course: course] ||
      UserIsCourseTeacher[user: requestor, course: course]
    when :read_task_plans
      UserIsCourseTeacher[user: requestor, course: course] ||
      course.cloned_courses.any? { |clone| UserIsCourseTeacher[user: requestor, course: clone] }
    when :export, :roster, :add_period, :update, :stats, :exercises, :lms_connection_info
      UserIsCourseTeacher[user: requestor, course: course]
    when :create
      requestor.can_create_courses?
    when :clone
      requestor.can_create_courses? &&
      (course.offering.nil? || course.offering.is_available) &&
      UserIsCourseTeacher[user: requestor, course: course]
    when :lms_sync_scores, :lms_course_pair, :lti_pair, :lti_scores
      course.environment.current? && UserIsCourseTeacher[user: requestor, course: course]
    else
      false
    end
  end
end
