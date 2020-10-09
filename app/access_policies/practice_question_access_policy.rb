class PracticeQuestionAccessPolicy
  def self.action_allowed?(action, requestor, question)
    return false unless requestor.is_human?
    case action
    when :read
      return true
    when :create, :destroy
      return question.role.user_profile_id == requestor.id
    else
      false
    end
  end
end
