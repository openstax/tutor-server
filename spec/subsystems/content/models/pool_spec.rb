require 'rails_helper'

RSpec.describe Content::Models::Pool, type: :model do
  subject(:pool) { FactoryBot.create :content_pool }

  it { is_expected.to belong_to(:ecosystem) }

  it { is_expected.to validate_presence_of(:ecosystem) }
  it { is_expected.to validate_presence_of(:pool_type) }
  it { is_expected.to validate_presence_of(:uuid) }

  it { is_expected.to validate_uniqueness_of(:uuid) }

  it 'returns exercises' do
    exercises = 10.times.map{ FactoryBot.create :content_exercise }
    pool.content_exercise_ids = exercises.map(&:id)
    expect(Set.new pool.exercises).to eq Set.new exercises
  end
end
