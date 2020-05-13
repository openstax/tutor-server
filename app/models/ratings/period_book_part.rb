class Ratings::PeriodBookPart < ApplicationRecord
  belongs_to :period, subsystem: :course_membership, inverse_of: :period_book_parts

  validates :book_part_uuid, presence: true, uniqueness: { scope: :course_membership_period_id }

  validates :clue, presence: true

  def num_responses
    tasked_exercise_ids.size
  end
end
