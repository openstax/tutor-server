class Book < ActiveRecord::Base
  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :edition, presence: true, uniqueness: { scope: :title }
end
