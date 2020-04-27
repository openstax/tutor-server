class CourseContent::Models::ExcludedExercise < ApplicationRecord
  belongs_to :course, subsystem: :course_profile

  validates :exercise_number, presence: true, uniqueness: { scope: :course_profile_course_id }
end
