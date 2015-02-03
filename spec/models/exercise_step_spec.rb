require 'rails_helper'

RSpec.describe ExerciseStep, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url, content, completed to its task_step" do
    exercise_step = FactoryGirl.create(:exercise_step)
    expect(exercise_step.url).to eq exercise_step.task_step.url
    expect(exercise_step.content).to eq exercise_step.task_step.content
    expect(exercise_step.completed_at).to(
      eq exercise_step.task_step.completed_at
    )
    expect(exercise_step.completed?).to eq exercise_step.task_step.completed?
    exercise_step.complete
    expect(exercise_step.completed_at).to(
      eq exercise_step.task_step.completed_at
    )
    expect(exercise_step.completed?).to eq exercise_step.task_step.completed?
  end
end
