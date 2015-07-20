class Entity::Course < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :course_profile

  has_many :periods, subsystem: :course_membership
  has_many :teachers, subsystem: :course_membership
  has_many :students, subsystem: :course_membership

  delegate :name, to: :profile
end
