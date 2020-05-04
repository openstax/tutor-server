class TaskPlanAccessPolicy
  TEACHER_ACTIONS = [:index, :read, :create, :update, :destroy, :restore]

  def self.action_allowed?(action, requestor, task_plan)
    return false if requestor.is_anonymous? || !requestor.is_human?

    # All logged in users are allowed to call index
    # The course it is called on will further restrict index permissions
    return true if action == :index

    return false unless TEACHER_ACTIONS.include?(action)

    course = task_plan.course
    UserIsCourseTeacher[user: requestor, course: course] || (
      action == :read &&
      course.cloned_courses.any? { |clone| UserIsCourseTeacher[user: requestor, course: clone] }
    )
  end
end
