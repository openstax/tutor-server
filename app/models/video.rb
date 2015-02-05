class Video < ActiveRecord::Base
  belongs_to_resource

  has_many :book_videos, dependent: :destroy
end
