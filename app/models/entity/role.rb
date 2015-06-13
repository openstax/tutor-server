class Entity::Role < Tutor::SubSystems::BaseModel
  enum role_type: [:unassigned, :default, :teacher, :student]

  has_many :students, dependent: :destroy, subsystem: :course_membership
  has_many :teachers, dependent: :destroy, subsystem: :course_membership
end
