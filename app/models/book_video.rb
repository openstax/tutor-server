class BookVideo < ActiveRecord::Base
  sortable_belongs_to :book, on: :number, inverse_of: :book_videos
  belongs_to :video

  validates :book, presence: true
  validates :video, presence: true, uniqueness: { scope: :book_id }
end
