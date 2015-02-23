class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && task.taskings.where(user_id: requestor.id).any?
    when :create, :update, :destroy
      false
    else
      false
    end
  end
end
