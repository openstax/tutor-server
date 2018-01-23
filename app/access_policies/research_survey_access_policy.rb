class ResearchSurveyAccessPolicy

  def self.action_allowed?(action, requestor, survey)
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :complete
      survey.student.role.role_user.user_profile_id == requestor.id
    else
      false
    end
  end

end
