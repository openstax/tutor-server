class UserProfile::CreateProfile
  lev_routine

  uses_routine Entity::CreateUser, translations: { outputs: { type: :verbatim } }

  protected

  def exec(attributes)
    run(:entity_create_user) unless attributes[:entity_user_id]
    attributes = default_attributes.merge(attributes)
    outputs[:profile] = UserProfile::Profile.create(attributes)
  end

  private

  def default_attributes
    {
      entity_user_id: outputs.user.id
    }
  end
end

