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
      UserIsCourseStudent[user: requestor, course: course] ||
      UserIsCourseTeacher[user: requestor, course: course]
    when :read_task_plans
      UserIsCourseTeacher[user: requestor, course: course] ||
      course.cloned_courses.any?{ |clone| UserIsCourseTeacher[user: requestor, course: clone] }
    when :export, :roster, :add_period, :update, :stats, :exercises
      UserIsCourseTeacher[user: requestor, course: course]
    when :create
      requestor.account.confirmed_faculty?
    when :clone
      UserIsCourseTeacher[user: requestor, course: course] &&
        course.offering.try!(:is_available)
    when :lms_connection_info
      UserIsCourseTeacher[user: requestor, course: course]
    when :lms_sync_scores
      UserIsCourseTeacher[user: requestor, course: course]
    else
      false
    end
  end

end
