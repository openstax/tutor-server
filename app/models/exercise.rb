class Exercise < ActiveRecord::Base
  belongs_to_resource

  has_many :book_exercises, dependent: :destroy
end
