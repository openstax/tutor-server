class Entity::User < Tutor::SubSystems::BaseModel
  def entity_role_id
    Role::Models::User.find_by(entity_user_id: id).id
  end
end
