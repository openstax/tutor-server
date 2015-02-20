class Exercise < ActiveRecord::Base
  acts_as_resource

  has_many :exercise_topics, dependent: :destroy
end
