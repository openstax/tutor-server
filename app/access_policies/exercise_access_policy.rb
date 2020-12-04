class ExerciseAccessPolicy
  def self.action_allowed?(action, requestor, exercise)
    return false if requestor.is_anonymous? || !requestor.is_human?

    case action
    when :delete
      exercise.user_profile_id == requestor.id
    else
      false
    end
  end
end
