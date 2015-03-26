class Content::Exercise < ActiveRecord::Base
  acts_as_resource

  has_many :exercise_tags, dependent: :destroy
end
