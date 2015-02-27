class Content::ExerciseTopic < ActiveRecord::Base
  sortable_belongs_to :content_exercise, on: :number, 
                                         inverse_of: :content_exercise_topics, 
                                         class_name: "::Content::Exercise"
  belongs_to :content_topic, class_name: "::Content::Topic"

  validates :content_exercise, presence: true
  validates :content_topic, presence: true, 
                            uniqueness: { scope: :content_exercise_id }
end
