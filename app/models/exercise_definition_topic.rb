class ExerciseDefinitionTopic < ActiveRecord::Base
  belongs_to :exercise_definition
  belongs_to :topic
end
