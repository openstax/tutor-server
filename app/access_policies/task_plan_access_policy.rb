class TaskPlanAccessPolicy
  TEACHER_ACTIONS = [:index, :read, :create, :update, :destroy, :restore]

  def self.action_allowed?(action, requestor, task_plan)
    return false if requestor.is_anonymous? || !requestor.is_human?

    # All logged in users are allowed to call index
    # The course it is called on will further restrict index permissions
    return true if action == :index

    return false unless TEACHER_ACTIONS.include?(action)

    owner = task_plan.owner

    if owner.is_a?(CourseProfile::Models::Course)
      UserIsCourseTeacher[user: requestor, course: owner] || (
        action == :read &&
        owner.cloned_courses.any? { |clone| UserIsCourseTeacher[user: requestor, course: clone] }
      )
    else
      requestor == owner
    end
  end
end
