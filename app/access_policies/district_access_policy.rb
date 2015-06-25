class DistrictAccessPolicy
  def self.action_allowed?(action, requestor, district)
    case action
    when :index
      true
    when :read
      true
    when :edit, :destroy, :update
      requestor.is_admin?
    else
      false
    end
  end
end
