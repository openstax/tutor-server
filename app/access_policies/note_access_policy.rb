class NoteAccessPolicy
  def self.action_allowed?(action, requestor, note)
    return false unless requestor.is_human?

    case action.to_sym
    when :read
      true
    when :create, :update, :destroy
      note.role.profile.account_id == requestor.id
    else
      false
    end
  end
end
