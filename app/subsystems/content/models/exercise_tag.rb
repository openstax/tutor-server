class Content::ExerciseTag < ActiveRecord::Base
  belongs_to :exercise
  belongs_to :tag

  validates :exercise, presence: true
  validates :tag, presence: true, uniqueness: { scope: :content_exercise_id }
end
