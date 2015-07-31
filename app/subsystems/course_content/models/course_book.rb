class CourseContent::Models::CourseBook < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity
  belongs_to :book, subsystem: :content

  validates :course, presence: true
  validates :book, presence: true

  validates :book, uniqueness: {scope: :entity_course_id}
end
