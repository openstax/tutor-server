class SchoolAccessPolicy
  # Contains all the rules for which requestors can do what with which School objects.

  def self.action_allowed?(action, requestor, school)
    case action
    when :index, :read # Anyone (non-anonymous)
      !requestor.is_anonymous?
    when :create, :destroy # Administrators only
      !requestor.is_anonymous? && requestor.is_human? && \
      !!requestor.administrator
    when :update # School managers and administrators
      !requestor.is_anonymous? && requestor.is_human? && \
      (requestor.school_managers.where(school_id: school.id).exists? || \
       !!requestor.administrator)
    else
      false
    end
  end

end
