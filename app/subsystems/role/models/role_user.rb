class Role::Models::RoleUser < Tutor::SubSystems::BaseModel
  belongs_to :profile, subsystem: :user
  belongs_to :role, subsystem: :entity

  validates :profile, presence: true
  validates :role, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :profile
end
