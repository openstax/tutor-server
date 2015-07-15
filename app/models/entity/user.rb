class Entity::User < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :user_profile

  has_one :role_user, class_name: '::Role::Models::User'

  delegate :username, :first_name, :last_name, :full_name, to: :profile
end
