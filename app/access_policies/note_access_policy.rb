class NoteAccessPolicy
  def self.action_allowed?(action, requestor, note)
    return false unless note.present? && requestor.is_human?

    case action.to_sym
    when :index, :read
      true
    when :create, :update, :destroy
      note.role.role_user.user_profile_id == requestor.id
    else
      false
    end
  end
end
