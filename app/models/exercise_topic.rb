class ExerciseTopic < ActiveRecord::Base
  belongs_to :exercise
  belongs_to :topic

  validates :topic, presence: true
  validates :exercise, presence: true, uniqueness: { scope: :topic_id }
end
