class BookReading < ActiveRecord::Base
  sortable_belongs_to :book, on: :number, inverse_of: :book_readings
  belongs_to :reading

  validates :book, presence: true
  validates :reading, presence: true, uniqueness: { scope: :book_id }
end
