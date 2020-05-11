class Ratings::ExerciseGroupBookPart < ApplicationRecord
  validates :exercise_group_uuid, :glicko_mu, :glicko_phi, :glicko_sigma, presence: true

  validates :book_part_uuid, presence: true, uniqueness: { scope: :exercise_group_uuid }
end
