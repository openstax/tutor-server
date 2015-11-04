class Cc::TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    return false if requestor.is_anonymous? || !requestor.is_human?

    action == :show
  end
end
