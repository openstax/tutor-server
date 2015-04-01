class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && 
      Domain::DoesTaskingExist[task_component: task, user: requestor]
    else
      false
    end
  end
end
