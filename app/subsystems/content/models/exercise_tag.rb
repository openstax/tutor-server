class Content::Models::ExerciseTag < IndestructibleRecord
  belongs_to :exercise, inverse_of: :exercise_tags
  belongs_to :tag, inverse_of: :exercise_tags

  validates :tag, uniqueness: { scope: :content_exercise_id }
end
