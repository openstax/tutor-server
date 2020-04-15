class Tasks::Models::Grading < ApplicationRecord
  belongs_to :tasked_exercise, inverse_of: :grading

  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
end
