class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read, :create, :update, :destroy, :mark_completed, :recover
      requestor.is_human? && 
      Domain::DoesTaskingExist[task_component: tasked, user: requestor]
    else
      false
    end
  end
end
