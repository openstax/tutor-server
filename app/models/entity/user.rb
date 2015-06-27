class Entity::User < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :user_profile

  delegate :first_name, :last_name, :full_name, to: :profile
end
