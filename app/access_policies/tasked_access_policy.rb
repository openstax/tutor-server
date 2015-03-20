class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read, :create, :update, :destroy, :mark_completed
      requestor.is_human? && tasked.tasked_to?(requestor)
    when :recover
      requestor.is_human? && tasked.tasked_to?(requestor) && \
      tasked.has_recovery?
    else
      false
    end
  end
end
