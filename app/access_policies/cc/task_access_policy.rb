class Cc::TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    return false if requestor.is_anonymous?

    action == :show
  end
end
