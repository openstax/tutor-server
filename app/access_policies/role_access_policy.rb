class RoleAccessPolicy
  def self.action_allowed?(action, requestor, role)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :become
      role.user_profile_id == requestor.id
    else
      false
    end
  end
end
