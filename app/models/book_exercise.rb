class BookExercise < ActiveRecord::Base
  sortable_belongs_to :book, on: :number, inverse_of: :book_exercises
  belongs_to :exercise

  validates :book, presence: true
  validates :exercise, presence: true, uniqueness: { scope: :book_id }
end
