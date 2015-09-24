class TaskPlanAccessPolicy
  def self.action_allowed?(action, requestor, task_plan)
    case action
    when :read, :create, :update, :destroy
      if task_plan.owner.is_a?(Entity::Course)
        UserIsCourseTeacher[user: requestor, course: task_plan.owner] rescue false
      elsif requestor.is_human?
        requestor_is_task_plan_owner?(requestor, task_plan.owner)
      else
        false
      end
    else
      false
    end
  end

  private

  def self.requestor_is_task_plan_owner?(requestor, owner)
    return true if requestor == owner

    # Check if the owner is the requestor's profile
    requestor.is_a?(::User::User) && \
    owner.is_a?(::User::Models::Profile) && \
    requestor.id == owner.id
  end

end
