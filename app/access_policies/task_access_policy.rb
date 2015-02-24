class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && task.any_tasks?(requestor)
    when :create, :update, :destroy
      false
    else
      false
    end
  end
end
