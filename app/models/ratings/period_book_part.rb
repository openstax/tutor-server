class Ratings::PeriodBookPart < ApplicationRecord
  INITIAL_MU = 0.0
  INITIAL_PHI = 2.015
  INITIAL_SIGMA = 0.06
  INITIAL_CLUE = {
    minimum: 0.0,
    most_likely: 0.5,
    maximum: 1.0,
    is_real: false
  }

  belongs_to :period, subsystem: :course_membership, inverse_of: :period_book_parts

  after_initialize :set_default_values

  validates :book_part_uuid, presence: true, uniqueness: { scope: :course_membership_period_id }

  validates :clue, presence: true

  def num_results
    tasked_exercise_ids.size
  end

  def set_default_values
    self.num_students ||= 0
    self.tasked_exercise_ids ||= []
    self.glicko_mu ||= INITIAL_MU
    self.glicko_phi ||= INITIAL_PHI
    self.glicko_sigma ||= INITIAL_SIGMA
    self.clue ||= INITIAL_CLUE
  end
end
