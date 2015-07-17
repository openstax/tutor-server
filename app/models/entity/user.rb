class Entity::User < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :user_profile

  has_many :role_user, subsystem: :role
  has_many :roles, through: :role_user

  delegate :username, :first_name, :last_name, :full_name, :name, to: :profile
end
