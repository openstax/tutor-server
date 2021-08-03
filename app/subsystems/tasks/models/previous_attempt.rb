class Tasks::Models::PreviousAttempt < ApplicationRecord
  belongs_to :tasked_exercise, inverse_of: :previous_attempts

  validates :number, presence: true, uniqueness: { scope: :tasks_tasked_exercise_id }
  validates :attempted_at, presence: true
end
