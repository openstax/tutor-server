class CourseContent::Models::ExerciseOptions < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity

  validates :course, presence: true
  validates :exercise_uid, presence: true

end
