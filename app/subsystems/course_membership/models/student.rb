class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :role, subsystem: :entity
  belongs_to :course, subsystem: :entity

  validates :entity_role_id,   presence: true, uniqueness: {scope: :entity_course_id}
  validates :entity_course_id, presence: true
end
