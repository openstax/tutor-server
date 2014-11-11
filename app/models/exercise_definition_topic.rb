class ExerciseDefinitionTopic < ActiveRecord::Base
  belongs_to :exercise_definition
  belongs_to :topic

  validates :exercise_definition, presence: true
  validates :topic, presence: true, 
                    uniqueness: { scope: :exercise_definition_id }
end
