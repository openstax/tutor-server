class ExerciseTopic < ActiveRecord::Base
  belongs_to :exercise
  belongs_to :topic

  validates :exercise, presence: true
  validates :topic, presence: true
  validates :topic_id, uniqueness: { scope: :exercise_id }
end
