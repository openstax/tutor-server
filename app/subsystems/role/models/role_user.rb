class Role::Models::RoleUser < Tutor::SubSystems::BaseModel
  belongs_to :user, subsystem: :entity
  belongs_to :role, subsystem: :entity

  validates :entity_user_id, presence: true
  validates :entity_role_id, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :user
end
