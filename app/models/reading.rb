class Reading < ActiveRecord::Base
  belongs_to_resource

  has_many :book_readings, dependent: :destroy
end
