class CourseContent::Models::CourseEcosystem < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity
  belongs_to :ecosystem, subsystem: :content

  validates :course, presence: true
  validates :ecosystem, presence: true

  default_scope -> { order(created_at: :desc) }

end
