require 'rails_helper'

RSpec.describe Ratings::ExerciseGroupBookPart, type: :model do
  subject(:exercise_book_part) { FactoryBot.create :ratings_exercise_group_book_part }

  it { is_expected.to validate_presence_of(:exercise_group_uuid) }

  it { is_expected.to validate_presence_of(:book_part_uuid) }

  it { is_expected.to validate_presence_of(:glicko_mu) }
  it { is_expected.to validate_presence_of(:glicko_phi) }
  it { is_expected.to validate_presence_of(:glicko_sigma) }

  it do
    is_expected.to(
      validate_uniqueness_of(:book_part_uuid).scoped_to(:exercise_group_uuid).case_insensitive
    )
  end
end
