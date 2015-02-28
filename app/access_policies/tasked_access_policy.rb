class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read, :create, :update, :destroy, :mark_completed
      requestor.is_human? && tasked.tasked_to?(requestor)
    else
      false
    end
  end
end
