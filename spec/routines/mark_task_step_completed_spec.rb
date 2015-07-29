require 'rails_helper'

RSpec.describe MarkTaskStepCompleted, type: :routine do

  let!(:tasked_reading) { FactoryGirl.create(:tasks_tasked_reading) }
  let!(:tasked_exercise) { FactoryGirl.create(:tasks_tasked_exercise) }

  it 'can mark a reading step as completed' do
    result = MarkTaskStepCompleted.call(task_step: tasked_reading.task_step)
    expect(result.errors).to be_empty
    expect(tasked_reading.task_step).to be_completed
  end

  # For the moment, exercise steps can be marked as completed, but this may change in the near term
  #
  # it 'cannot mark an exercise step as completed' do
  #   result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
  #   expect(result.errors.collect{|error| error.code}).to eq [:step_type_cannot_be_marked_completed]
  #   expect(tasked_exercise.task_step).not_to be_completed
  # end

  it 'can mark an exercise step as completed' do
    allow(tasked_exercise).to receive(:identifiers).and_return([42])
    result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
    expect(result.errors).to be_empty
    expect(tasked_exercise.task_step).to be_completed
  end

  it 'instructs the associated Task to handle completion-related activities' do
    task_step = tasked_reading.task_step
    task = task_step.task

    expect(task_step).to receive(:complete)
    expect(task_step).to receive(:save)
    allow(task_step).to receive(:task).and_return(task)
    expect(task).to receive(:handle_task_step_completion!)

    result = MarkTaskStepCompleted.call(task_step: task_step)

    expect(result.errors).to be_empty
  end

  it 'instructs the associated Tasked to handle completion-related activities' do
    # lock! calls reload, which reloads the instances of task_step's associations
    expect_any_instance_of(Tasks::Models::TaskedExercise).to receive(:handle_task_step_completion!)
    result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
    expect(result.errors).to be_empty
  end

end
