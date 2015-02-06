class Exercise < ActiveRecord::Base
  belongs_to_resource

  has_many :page_exercises, dependent: :destroy
end
