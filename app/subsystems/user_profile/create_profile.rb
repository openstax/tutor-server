class UserProfile::CreateProfile
  lev_routine

  protected

  def exec(attributes)
    outputs[:user] = Entity::User.create! unless attributes[:entity_user_id]
    attributes = default_attributes.merge(attributes)
    outputs[:profile] = UserProfile::Models::Profile.create(attributes)
  end

  private

  def default_attributes
    {
      entity_user_id: outputs.user.id
    }
  end
end

