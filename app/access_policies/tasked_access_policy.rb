class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read, :create, :update, :destroy, :mark_completed
      requestor.is_human? && tasked.any_tasks?(requestor)
    else
      false
    end
  end
end
