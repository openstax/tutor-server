class TaskPlanAccessPolicy
  VALID_ACTIONS = [:index, :read, :create, :update, :destroy, :restore]

  def self.action_allowed?(action, requestor, task_plan)
    return false if requestor.is_anonymous? || !requestor.is_human?

    # In principle, any logged in user is allowed to call index
    # The course it is called on will further restrict index permissions
    return true if action == :index

    return false unless VALID_ACTIONS.include?(action)

    owner = task_plan.owner

    if owner.is_a?(CourseProfile::Models::Course)
      UserIsCourseTeacher[user: requestor, course: owner] ||
      ( action == :read &&
        owner.cloned_courses.any?{ |clone| UserIsCourseTeacher[user: requestor, course: clone] } )
    elsif requestor.is_human?
      requestor == owner || requestor.to_model == owner
    else
      false
    end
  end
end
