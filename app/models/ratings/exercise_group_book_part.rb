class Ratings::ExerciseGroupBookPart < ApplicationRecord
  INITIAL_MU = 0.0
  INITIAL_PHI = 2.015
  INITIAL_SIGMA = 0.06

  attr_accessor :response

  after_initialize :set_default_values

  validates :exercise_group_uuid, :glicko_mu, :glicko_phi, :glicko_sigma, presence: true

  validates :book_part_uuid, presence: true, uniqueness: { scope: :exercise_group_uuid }

  def num_responses
    tasked_exercise_ids.size
  end

  def set_default_values
    self.tasked_exercise_ids ||= []
    self.glicko_mu ||= INITIAL_MU
    self.glicko_phi ||= INITIAL_PHI
    self.glicko_sigma ||= INITIAL_SIGMA
  end
end
