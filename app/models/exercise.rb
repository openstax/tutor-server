class Exercise < ActiveRecord::Base
  belongs_to_resource

  has_many :exercise_topics, dependent: :destroy
end
