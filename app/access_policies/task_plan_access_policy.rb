class TaskPlanAccessPolicy
  def self.action_allowed?(action, requestor, task_plan)
    case action
    when :read, :create, :update, :destroy
      if task_plan.owner.is_a?(Entity::Course)
        UserIsCourseTeacher[user: requestor.entity_user,
                            course: task_plan.owner] rescue false
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
    requestor == owner || requestor.entity_user == owner
  end

end
