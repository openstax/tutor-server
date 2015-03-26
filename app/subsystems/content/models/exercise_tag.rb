class Content::ExerciseTag < ActiveRecord::Base
  sortable_belongs_to :exercise, on: :number, inverse_of: :exercise_tags
  belongs_to :tag

  validates :exercise, presence: true
  validates :tag, presence: true, uniqueness: { scope: :content_exercise_id }
end
