class TaskPlanAccessPolicy
  VALID_ACTIONS = [:index, :read, :create, :update, :destroy, :restore]

  def self.action_allowed?(action, requestor, task_plan)
    return false unless VALID_ACTIONS.include?(action)

    # In principle, any logged in user is allowed to call index
    # The course it is called on will further restrict index permissions
    return requestor.is_human? && !requestor.is_anonymous? if action == :index

    owner = task_plan.owner

    if owner.is_a?(CourseProfile::Models::Course)
      UserIsCourseTeacher[user: requestor, course: owner]
    elsif requestor.is_human?
      requestor == owner || requestor.to_model == owner
    else
      false
    end
  end
end
