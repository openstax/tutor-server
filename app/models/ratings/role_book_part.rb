class Ratings::RoleBookPart < ApplicationRecord
  belongs_to :role, subsystem: :entity, inverse_of: :role_book_parts

  validates :book_part_uuid, presence: true, uniqueness: { scope: :entity_role_id }

  validates :clue, :glicko_mu, :glicko_phi, :glicko_sigma, presence: true

  def num_responses
    tasked_exercise_ids.size
  end
end
