class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :index
      requestor.is_human? && !requestor.is_anonymous?
    when :read
      requestor.is_human? && !requestor.is_anonymous? && task.users.include?(requestor)
    when :create, :update, :destroy
      false
    else
      false
    end
  end
end