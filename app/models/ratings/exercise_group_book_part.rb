class Ratings::ExerciseGroupBookPart < ApplicationRecord
  attr_accessor :response

  validates :exercise_group_uuid, :glicko_mu, :glicko_phi, :glicko_sigma, presence: true

  validates :book_part_uuid, presence: true, uniqueness: { scope: :exercise_group_uuid }

  def num_responses
    tasked_exercise_ids.size
  end
end
