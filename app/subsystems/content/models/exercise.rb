class Content::Exercise < ActiveRecord::Base
  acts_as_resource

  has_many :content_exercise_topics, dependent: :destroy,
                                     class_name: "::Content::ExerciseTopic",
                                     inverse_of: :content_exercise,
                                     foreign_key: "content_exercise_id"
end
