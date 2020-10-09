class Tasks::Models::PracticeQuestion < ApplicationRecord
  #belongs_to :tasked_exercise, subsystem: :tasks
  belongs_to :role, subsystem: :entity, inverse_of: :practice_questions

  validates :tasked_exercise_id, presence: true
  validates :exercise_number, presence: true, uniqueness: { scope: [:exercise_version, :entity_role_id] }
  validates :exercise_version, presence: true

  def available?
    tasked_exercise.published_grader_points.present?
  end

  def tasked_exercise
    ::Tasks::Models::TaskedExercise.find(tasked_exercise_id)
  end
end
