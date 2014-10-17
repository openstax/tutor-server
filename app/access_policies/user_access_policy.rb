class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    case action
    when :index # Anyone (non-anonymous)
      !requestor.is_anonymous?
    when :read, :update, :destroy # The user himself and administrators
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor == user || !!requestor.administrator)
    else
      false
    end
  end

end
