class Role::Models::RoleUser < Tutor::SubSystems::BaseModel
  belongs_to :user, subsystem: :entity
  belongs_to :role, subsystem: :entity

  validates :user, presence: true
  validates :role, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :user
end
