class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && task.tasked_to?(requestor)
    else
      false
    end
  end
end
