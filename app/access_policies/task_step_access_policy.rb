class TaskStepAccessPolicy
  def self.action_allowed?(action, requestor, task_step)
    case action
    when :read
      requestor.is_human? && step_tasked_to_requestor?(task_step, requestor)
    when :create, :update, :destroy
      requestor.is_human? && step_tasked_to_requestor?(task_step, requestor)
    when :mark_completed
      requestor.is_human? && step_tasked_to_requestor?(task_step, requestor)
    else
      false
    end
  end

  def self.step_tasked_to_requestor?(task_step, requestor)
    Tasking.joins{task.task_steps}
           .where{task.task_steps.id == my{task_step.id}}
           .where{user_id == requestor.id}
           .any?
  end
end