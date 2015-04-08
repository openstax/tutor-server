require 'rails_helper'

RSpec.describe FillIReadingSpacedPracticeSlot, :type => :routine do

  let!(:user) { FactoryGirl.create :user_profile }

  it 'returns a fake exercise hash' do
    result = FillIReadingSpacedPracticeSlot.call(user, 1)
    exercise = result.outputs.exercise
    expect(exercise.content).not_to be_blank
    expect(exercise.content_hash).to have_key('stimulus_html')
                                       .and have_key('questions')
    expect(exercise.uid).not_to be_blank
  end

  it 'consecutive calls have different exercise uids' do
    exercise1 = FillIReadingSpacedPracticeSlot.call(user, 1).outputs.exercise
    exercise2 = FillIReadingSpacedPracticeSlot.call(user, 1).outputs.exercise
    expect(exercise1.id).to_not eq(exercise2.id)
  end

end
