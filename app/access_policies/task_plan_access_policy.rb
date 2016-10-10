class TaskPlanAccessPolicy
  VALID_ACTIONS = [:read, :create, :update, :destroy, :restore]

  def self.action_allowed?(action, requestor, task_plan)
    return false if !VALID_ACTIONS.include?(action)

    owner = task_plan.owner

    if owner.is_a?(Entity::Course)
      return false if action == :create && !owner.active?

      UserIsCourseTeacher[user: requestor, course: owner]
    elsif requestor.is_human?
      requestor == owner || requestor.to_model == owner
    else
      false
    end
  end
end
