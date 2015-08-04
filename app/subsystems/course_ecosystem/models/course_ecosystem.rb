class CourseEcosystem::Models::CourseEcosystem < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity
  belongs_to :ecosystem, subsystem: :content

  validates :course, presence: true
  validates :ecosystem, presence: true

  validates :ecosystem, uniqueness: {scope: :entity_course_id}

  default_scope -> { order(created_at: :desc) }
end
