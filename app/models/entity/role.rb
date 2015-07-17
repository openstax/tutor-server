class Entity::Role < Tutor::SubSystems::BaseModel
  enum role_type: [:unassigned, :default, :teacher, :student]

  has_many :students, dependent: :destroy, subsystem: :course_membership
  has_many :teachers, dependent: :destroy, subsystem: :course_membership

  has_one :role_user, dependent: :destroy, subsystem: :role
  has_one :user, through: :role_user

  delegate :username, :first_name, :last_name, :full_name, to: :user
end
