class JobAccessPolicy
  def self.action_allowed?(action, requestor, job)
    return false unless requestor.is_human?

    case action
    when :index
      requestor.is_admin?
    when :read
      true
    else
      false
    end
  end
end
