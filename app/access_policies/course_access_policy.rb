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
    when :export, :roster, :add_period, :update, :stats, :exercises
      UserIsCourseTeacher[user: requestor, course: course]
    when :create
      requestor.account.confirmed_faculty? && !requestor.account.foreign_school? && (
        requestor.account.college? ||
        requestor.account.high_school? ||
        requestor.account.k12_school? ||
        requestor.account.home_school?
      )
    when :clone
      requestor.account.confirmed_faculty? &&
      UserIsCourseTeacher[user: requestor, course: course] &&
      course.offering&.is_available
    when :lms_connection_info, :lms_sync_scores, :lms_course_pair
      UserIsCourseTeacher[user: requestor, course: course]
    else
      false
    end
  end

end
