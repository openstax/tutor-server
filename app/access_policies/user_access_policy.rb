class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    case action
    when :index # Anyone (non-anonymous)
      !requestor.is_anonymous?
    when :read, :update, :destroy, :read_tasks # The user himself
      !requestor.is_anonymous? && requestor == user
    else
      false
    end
  end

end
