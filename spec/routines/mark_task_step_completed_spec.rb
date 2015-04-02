require 'rails_helper'

RSpec.describe MarkTaskStepCompleted, :type => :routine do

  let!(:tasked_reading) { FactoryGirl.create(:tasks_tasked_reading) }
  let!(:tasked_exercise) { FactoryGirl.create(:tasks_tasked_exercise) }

  it 'can mark a reading step as completed' do
    result = MarkTaskStepCompleted.call(task_step: tasked_reading.task_step)
    expect(result.errors).to be_empty
    expect(tasked_reading.task_step.completed_at).not_to be_nil
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

  it 'instructs the associated Task to handle completion-related activities' do
    task = Tasks::Models::Task.new
    task_step = Tasks::Models::TaskStep.new
    expect(task_step).to receive(:complete)
    expect(task_step).to receive(:save)
    expect(task_step).to receive(:task).and_return(task)
    expect(task).to receive(:handle_task_step_completion!).with(hash_including(task_step: task_step))

    result = MarkTaskStepCompleted.call(task_step: task_step)

    expect(result.errors).to be_empty
  end

end
