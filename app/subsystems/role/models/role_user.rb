class Role::Models::RoleUser < Tutor::SubSystems::BaseModel
  belongs_to :profile, -> { with_deleted }, subsystem: :user
  belongs_to :role, subsystem: :entity

  validates :profile, presence: true
  validates :role, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :profile
end
