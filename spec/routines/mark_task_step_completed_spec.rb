require 'rails_helper'

RSpec.describe MarkTaskStepCompleted, type: :routine do
  let(:tasked_reading)  { FactoryBot.create(:tasks_tasked_reading) }
  let(:tasked_exercise) { FactoryBot.create(:tasks_tasked_exercise) }

  it 'can mark a reading step as completed' do
    result = MarkTaskStepCompleted.call(task_step: tasked_reading.task_step)
    expect(result.errors).to be_empty
    expect(tasked_reading.task_step).to be_completed
  end

  it 'can mark an exercise step as completed' do
    # lock! calls reload, which reloads the instances of task_step's associations
    # this is why we use expect_any_instance_of
    expect_any_instance_of(tasked_exercise.class).to receive(:valid?)
    expect_any_instance_of(tasked_exercise.class).to receive(:before_completion)

    result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
    expect(result.errors).to be_empty
    expect(tasked_exercise.task_step).to be_completed
  end

  it 'instructs the associated Task to handle completion-related activities' do
    task_step = tasked_reading.task_step
    task = task_step.task

    expect(task_step).to receive(:complete).and_call_original
    expect(task_step).to receive(:save!).and_call_original

    expect(task).to receive(:handle_task_step_completion).and_call_original
    expect_any_instance_of(Tasks::Models::Task).to receive(:update_caches_later).and_call_original

    expect do
      result = MarkTaskStepCompleted.call(task_step: task_step)
      expect(result.errors).to be_empty
    end.to change { task.reload.completed_steps_count }.from(0).to(1)
  end

  it 'returns an error if the answer_id is missing for an exercise' do
    result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)
    expect(result.errors).not_to be_empty
    expect(result.errors).to have_offending_input :tasked
    expect(result.errors.map(&:code)).to eq [ :'Answer is required' ]

    expect(tasked_exercise.reload.task_step).not_to be_completed
  end

  it 'closes a practice task when completing the remaining step' do
    task = tasked_exercise.task_step.task
    task.update_attributes!(due_at: nil, closes_at: nil, task_type: :practice_worst_topics)

    expect_any_instance_of(tasked_exercise.class).to receive(:valid?)
    expect_any_instance_of(tasked_exercise.class).to receive(:before_completion)
    result = MarkTaskStepCompleted.call(task_step: tasked_exercise.task_step)

    expect(task.due_at_ntz).not_to be(nil)
    expect(task.closes_at_ntz).not_to be(nil)
  end
end
