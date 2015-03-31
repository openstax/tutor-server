class UserProfile::Models::User < Tutor::SubSystems::BaseModel
  ## using class_name as workaround, see: https://github.com/rails/rails/issues/15811
  belongs_to :entity_user, class_name: "::Entity::Models::User"

  validates :user_id,        presence: true
  validates :entity_user_id, presence: true
end
