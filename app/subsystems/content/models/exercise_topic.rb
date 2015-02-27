class Content::ExerciseTopic < ActiveRecord::Base
  sortable_belongs_to :exercise, on: :number, 
                                         inverse_of: :exercise_topics

  belongs_to :topic

  validates :exercise, presence: true
  validates :topic, presence: true, 
                            uniqueness: { scope: :content_exercise_id }
end
