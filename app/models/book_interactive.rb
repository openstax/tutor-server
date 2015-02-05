class BookInteractive < ActiveRecord::Base
  sortable_belongs_to :book, on: :number, inverse_of: :book_interactives
  belongs_to :interactive

  validates :book, presence: true
  validates :interactive, presence: true, uniqueness: { scope: :book_id }
end
