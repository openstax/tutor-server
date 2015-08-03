class Entity::Course < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :course_profile

  has_many :periods, subsystem: :course_membership
  has_many :teachers, subsystem: :course_membership
  has_many :students, subsystem: :course_membership

  has_many :course_ecosystems, subsystem: :course_ecosystem
  has_many :ecosystems, through: :course_ecosystems, subsystem: :ecosystem

  delegate :name, to: :profile
end
