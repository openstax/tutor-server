class CourseContent::Models::ExcludedExercise < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity

  validates :course, presence: true
  validates :number, presence: true, uniqueness: { scope: :entity_course_id }

end
