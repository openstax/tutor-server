class SuggestionAccessPolicy

  def self.action_allowed?(action, requestor, suggestion)
    return false if requestor.is_anonymous? || requestor.account.student?

    true
  end

end
