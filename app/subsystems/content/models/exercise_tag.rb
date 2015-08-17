class Content::Models::ExerciseTag < Tutor::SubSystems::BaseModel
  belongs_to :exercise, inverse_of: :exercise_tags
  belongs_to :tag, inverse_of: :exercise_tags

  # These validations are by far the most consuming for all specs and the demo script
  # They are also enforced by the DB through non-null columns,
  # foreign key constraints and unique indices
  # Therefore, we decided to disable them until a bulk validation solution is available
  # validates :exercise, presence: true
  # validates :tag, presence: true, uniqueness: { scope: :content_exercise_id }
end
