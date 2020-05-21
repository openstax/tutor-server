class Ratings::RoleBookPart < ApplicationRecord
  INITIAL_MU = 0.0
  INITIAL_PHI = 2.015
  INITIAL_SIGMA = 0.06
  INITIAL_CLUE = {
    minimum: 0.0,
    most_likely: 0.5,
    maximum: 1.0,
    is_real: false
  }

  belongs_to :role, subsystem: :entity, inverse_of: :role_book_parts

  after_initialize :set_default_values

  validates :book_part_uuid, presence: true, uniqueness: { scope: :entity_role_id }

  validates :clue, :glicko_mu, :glicko_phi, :glicko_sigma, presence: true

  def num_responses
    tasked_exercise_ids.size
  end

  def set_default_values
    self.tasked_exercise_ids ||= []
    self.glicko_mu ||= INITIAL_MU
    self.glicko_phi ||= INITIAL_PHI
    self.glicko_sigma ||= INITIAL_SIGMA
    self.clue ||= INITIAL_CLUE
  end
end
