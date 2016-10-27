class OfferingAccessPolicy
  def self.action_allowed?(action, requestor, offering)
    return false if requestor.is_anonymous? || !requestor.is_human?

    case action.to_sym
    when :index
      requestor.account.confirmed_faculty?
    when :read
      requestor.account.confirmed_faculty? && offering.is_available
    else
      false
    end
  end
end
