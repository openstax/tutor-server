class Topic < ActiveRecord::Base
  belongs_to :klass
  has_many :exercise_definition_topics, dependent: :destroy
  has_many :exercise_definitions, through: :exercise_definition_topics

  validates :klass, presence: true
end
