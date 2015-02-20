class TaskedExercise < ActiveRecord::Base
  acts_as_tasked

  has_many :exercise_substeps, inverse_of: :tasked_exercise

  validates :url, presence: true
  validates :content, presence: true
end
