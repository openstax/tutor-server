class TaskAccessPolicy
  # Contains all the rules for which requestors can do what with which UserGroup objects.
  def self.action_allowed?(action, requestor, task)
    raise NotYetImplemented
    # case action
    # when :read
    # when :create, :update, :destroy
    # else
    #   false
    # end
  end
end