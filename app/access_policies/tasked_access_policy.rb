class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read
      requestor.is_human? && tasked_to_requestor?(tasked, requestor)
    when :create, :update, :destroy
      requestor.is_human? && tasked_to_requestor?(tasked, requestor)
    when :mark_completed
      requestor.is_human? && tasked_to_requestor?(tasked, requestor)
    else
      false
    end
  end

  def self.tasked_to_requestor?(tasked, requestor)
    requestor.id.present? &&
      tasked.task_step.task.taskings.where(user_id: requestor.id).any?
  end
end