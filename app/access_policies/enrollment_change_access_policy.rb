class EnrollmentChangeAccessPolicy
  def self.action_allowed?(action, requestor, enrollment_change)
    return false if requestor.is_anonymous? || !requestor.is_human?

    case action
    when :create
      true # A (normal) user is always allowed to create EnrollmentChanges for themselves
    when :approve
      requestor == enrollment_change.profile
    else
      false
    end
  end
end
