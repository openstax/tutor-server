class OfferingAccessPolicy
  def self.action_allowed?(action, requestor, offering)
    return false if requestor.is_anonymous? ||
                    !requestor.is_human? ||
                    !requestor.account.confirmed_faculty? ||
                    requestor.account.foreign_school? ||
                    !(
                      requestor.account.college? ||
                      requestor.account.high_school? ||
                      requestor.account.k12_school? ||
                      requestor.account.home_school?
                    )

    case action.to_sym
    when :index, :read
      true
    when :create_preview
      offering.is_preview_available
    when :create_course
      offering.is_available
    else
      false
    end
  end
end
