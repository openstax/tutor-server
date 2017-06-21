class AllowAllAccessPolicy
  def self.action_allowed?(action, requestor, resource)
    return true
  end
end
