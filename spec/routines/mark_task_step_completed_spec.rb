require 'rails_helper'

RSpec.describe MarkTaskStepCompleted, :type => :routine do

  let!(:tasked_reading) { FactoryGirl.create(:tasked_reading) }
  let!(:tasked_interactive) { FactoryGirl.create(:tasked_interactive) }
  let!(:tasked_exercise) { FactoryGirl.create(:tasked_exercise) }

  it 'can mark a reading step as completed' do
    result = MarkTaskStepCompleted.call(task_step: tasked_reading.task_step)
    expect(result.errors).to be_empty
    expect(tasked_reading.task_step.completed_at).not_to be_nil
  end

  it 'can mark an interactive step as completed' do
    result = MarkTaskStepCompleted.call(task_step: tasked_interactive.task_step)
    expect(result.errors).to be_empty
    expect(tasked_interactive.task_step.completed_at).not_to be_nil
  end

  # For the moment, exercise steps can be marked as completed, but this may change in the near term
  #
  # it 'cannot mark an exercise step as completed' do
  #   result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
  #   expect(result.errors.collect{|error| error.code}).to eq [:step_type_cannot_be_marked_completed]
  #   expect(tasked_exercise.task_step.completed_at).to be_nil
  # end

  it 'can mark an exercise step as completed' do
    result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
    expect(result.errors).to be_empty
    expect(tasked_exercise.task_step.completed_at).not_to be_nil
  end

end
