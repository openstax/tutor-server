require 'rails_helper'

RSpec.describe FillIReadingSpacedPracticeSlot, :type => :routine do

  it 'returns a fake exercise hash' do
    result = FillIReadingSpacedPracticeSlot.call
    exercise_hash = result.outputs.exercise_hash
    expect(exercise_hash).to have_key(:content)
    expect(exercise_hash[:content]).to have_key(:stimulus_html).and have_key(:questions)
    expect(exercise_hash).to have_key(:tags)
    expect(exercise_hash).to have_key(:id)
    expect(exercise_hash).to have_key(:version)
  end

  it 'consecutive calls have different exercise ids' do
    exercise_hash1 = FillIReadingSpacedPracticeSlot.call.outputs.exercise_hash
    exercise_hash2 = FillIReadingSpacedPracticeSlot.call.outputs.exercise_hash
    expect(exercise_hash1[:id]).to_not eq(exercise_hash2[:id])
  end
  
end
