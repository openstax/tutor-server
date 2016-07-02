class Content::Models::ExerciseTag < Tutor::SubSystems::BaseModel
  belongs_to :exercise, inverse_of: :exercise_tags
  belongs_to :tag, inverse_of: :exercise_tags

  validates :exercise, presence: true
  validates :tag, presence: true, uniqueness: { scope: :content_exercise_id }
end
