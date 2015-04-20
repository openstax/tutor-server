class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read, :mark_completed, :recover, :refresh
      requestor.is_human? && DoesTaskingExist[task_component: tasked, user: requestor]
    when :update
      requestor.is_human? && DoesTaskingExist[task_component: tasked, user: requestor] && \
      tasked.can_be_answered? && !tasked.task_step.task.feedback_available?
      # Replace with !tasked.task_step.task.feedback_viewed? when implemented
    else
      false
    end
  end
end
