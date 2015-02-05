class Book < ActiveRecord::Base
  belongs_to_resource

  has_many :book_readings, dependent: :destroy
  has_many :book_exercises, dependent: :destroy
  has_many :book_interactives, dependent: :destroy
  has_many :book_videos, dependent: :destroy
end
