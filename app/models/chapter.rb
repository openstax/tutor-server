class Chapter < ActiveRecord::Base
  sortable_belongs_to :book, on: :number, inverse_of: :chapters

  has_many :pages, dependent: :destroy

  validates :book, presence: true
  validates :title, presence: true, uniqueness: { scope: :book_id }
end
