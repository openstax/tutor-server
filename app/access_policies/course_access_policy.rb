class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    return false if requestor.is_anonymous? || !requestor.is_human?

    case action.to_sym
    when :index
      true
    when :read, :task_plans
      UserIsCourseStudent[user: requestor, course: course] ||
      UserIsCourseTeacher[user: requestor, course: course]
    when :export, :roster, :add_period, :update, :stats, :exercises, :clone
      UserIsCourseTeacher[user: requestor, course: course]
    when :create
      # TODO: verified faculty
      false
    else
      false
    end
  end
end
