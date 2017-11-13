# TODO: Each role belongs to exactly 1 user and several parts of the system assume this
#       Remove this class and add a user_profile_id to Entity::Role
class Role::Models::RoleUser < IndestructibleRecord
  belongs_to :profile, subsystem: :user
  belongs_to :role, subsystem: :entity

  validates :profile, presence: true
  validates :role, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :profile
end
