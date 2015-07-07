class CourseAccessPolicy
  def self.action_allowed?(action, requestor, course)
    case action
    when :index
      !requestor.is_anonymous?
    when :read, :readings, :task_plans
      # readings should be readable by course teachers and students because FE
      # uses it for the reference view
      requestor.is_human? &&
        (requestor.is_admin? ||
          UserIsCourseStudent[user: requestor.entity_user, course: course] ||
            UserIsCourseTeacher[user: requestor.entity_user, course: course])
    when :exercises, :export, :roster
      requestor.is_human? && UserIsCourseTeacher[user: requestor.entity_user, course: course]
    else
      false
    end
  end
end
