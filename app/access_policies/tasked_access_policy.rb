
class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read, :create, :update, :destroy, :mark_completed
      requestor.is_human? && tasked_to?(requestor, tasked)
    when :recover
      requestor.is_human? && tasked_to?(requestor, tasked) && tasked.has_recovery?
    else
      false
    end
  end

  def self.tasked_to?(requestor, tasked)
    Domain::DoesTaskingExist[task_component: tasked, user: requestor]
  end
end
