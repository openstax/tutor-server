require 'rails_helper'

RSpec.describe Tasks::AddRelatedExerciseAfterStep, type: :routine do

  let(:lo)              { FactoryBot.create :content_tag, value: 'ost-tag-lo-test-lo01' }
  let(:pp)              { FactoryBot.create :content_tag, value: 'os-practice-problems' }

  let(:tasked_reading)  { FactoryBot.create(:tasks_tasked_reading) }

  let(:task)            { tasked_reading.task_step.task }

  let!(:tasking)        { FactoryBot.create :tasks_tasking, task: task }

  let(:tasked_exercise) do
    te = FactoryBot.build(:tasks_tasked_exercise)
    te.task_step.task = task.reload
    te.save!
    te
  end

  let(:related_exercise) { FactoryBot.create :content_exercise, tags: [lo.value, pp.value] }

  let(:tasked_exercise_with_related) do
    te = FactoryBot.build(:tasks_tasked_exercise)
    te.task_step.task = task.reload
    te.task_step.related_exercise_ids = [related_exercise.id]
    te.save!
    te
  end

  let(:step_after_exercise)  { FactoryBot.create(:tasks_task_step, task: task.reload) }

  let(:tasked_reading_with_related) do
    te = FactoryBot.build(:tasks_tasked_reading)
    te.task_step.task = task.reload
    te.task_step.related_exercise_ids = [related_exercise.id]
    te.save!
    te
  end

  let(:step_after_reading)  { FactoryBot.create(:tasks_task_step, task: task.reload) }

  it "cannot be called on task_steps with no related_exercise_ids" do
    expect {
      @result = described_class.call(task_step: tasked_reading.task_step)
    }.not_to change{ tasked_reading.task_step }
    expect(@result.errors.first.code).to eq(:related_exercise_not_available)

    expect {
      @result = described_class.call(task_step: tasked_exercise.task_step)
    }.not_to change{ tasked_reading.task_step }
    expect(@result.errors.first.code).to eq(:related_exercise_not_available)
  end

  it "adds a new exercise step after exercise steps" do
    task_step = tasked_exercise_with_related.task_step
    expect { @result = described_class.call(task_step: task_step) }.to(
      change{ @related_exercise_step = task_step.reload.next_by_number }
    )

    expect(@result.errors).to be_empty
    expect(@related_exercise_step).to eq @result.outputs.related_exercise_step
    expect(@related_exercise_step.group_type).to eq 'recovery_group'
    related_exercise_tasked = @related_exercise_step.tasked
    expect(related_exercise_tasked.url).to eq related_exercise.url
    expect(related_exercise_tasked.title).to eq related_exercise.title
    expect(related_exercise_tasked.content).to eq related_exercise.content
    expect(step_after_exercise.reload.number).to eq @related_exercise_step.number + 1
  end

  it "adds a new exercise step after reading steps" do
    task_step = tasked_reading_with_related.task_step
    expect { @result = described_class.call(task_step: task_step) }.to(
      change{ @related_exercise_step = task_step.reload.next_by_number }
    )

    expect(@result.errors).to be_empty
    expect(@related_exercise_step).to eq @result.outputs.related_exercise_step
    expect(@related_exercise_step.group_type).to eq 'recovery_group'
    related_exercise_tasked = @related_exercise_step.tasked
    expect(related_exercise_tasked.url).to eq related_exercise.url
    expect(related_exercise_tasked.title).to eq related_exercise.title
    expect(related_exercise_tasked.content).to eq related_exercise.content
    expect(step_after_reading.reload.number).to eq @related_exercise_step.number + 1
  end

end
