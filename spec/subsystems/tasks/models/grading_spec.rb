require 'rails_helper'

RSpec.describe Tasks::Models::Grading, type: :model do
  subject(:grading) { FactoryBot.create :tasks_grading }

  it { is_expected.to belong_to(:tasked_exercise) }

  it { is_expected.to validate_presence_of(:points) }

  it { is_expected.to validate_numericality_of(:points).is_greater_than_or_equal_to(0.0) }
end
