class ExerciseDefinition < ActiveRecord::Base
  belongs_to :klass
  has_many :exercise_definition_topics, dependent: :destroy
  has_many :topics, through: :exercise_definition_topics

  serialize :content

  validates :klass, presence: true
  validates :url, presence: true,
                  uniqueness: {scope: :klass_id}
end
