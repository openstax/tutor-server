require 'rails_helper'

RSpec.describe Tasks::Models::PreviousAttempt, type: :model do
  subject(:previous_attempt) { FactoryBot.create :tasks_previous_attempt }

  it { is_expected.to belong_to :tasked_exercise }

  it { is_expected.to validate_presence_of :number }
  it { is_expected.to validate_uniqueness_of(:number).scoped_to(:tasks_tasked_exercise_id) }

  it { is_expected.to validate_presence_of :attempted_at }
end
