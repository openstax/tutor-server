require 'rails_helper'

RSpec.describe ExerciseSubstep, :type => :model do
  it { is_expected.to belong_to(:tasked_exercise) }
  it { is_expected.to belong_to(:subtasked) }

  it { is_expected.to validate_presence_of(:tasked_exercise) }
  it { is_expected.to validate_presence_of(:subtasked) }

  it "requires subtasked to be unique" do
    exercise_substep = FactoryGirl.create(:exercise_substep)
    expect(exercise_substep).to be_valid

    expect(FactoryGirl.build(
      :exercise_substep, subtasked: exercise_substep.subtasked
    )).to_not be_valid
  end
end
