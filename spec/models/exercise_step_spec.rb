require 'rails_helper'

RSpec.describe ExerciseStep, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url and content to its task_step" do
    exercise_step = FactoryGirl.create(:exercise_step)
    expect(exercise_step.url).to eq exercise_step.task_step.url
    expect(exercise_step.content).to eq exercise_step.task_step.content
  end
end
