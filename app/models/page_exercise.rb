class PageExercise < ActiveRecord::Base
  sortable_belongs_to :page, on: :number, inverse_of: :page_exercises
  belongs_to :exercise

  validates :page, presence: true
  validates :exercise, presence: true, uniqueness: { scope: :page_id }
end
