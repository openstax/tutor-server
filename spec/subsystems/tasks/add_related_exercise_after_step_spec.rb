require 'rails_helper'

RSpec.describe Tasks::AddRelatedExerciseAfterStep, type: :routine do

  let!(:lo)              { FactoryGirl.create :content_tag, value: 'ost-tag-lo-test-lo01' }
  let!(:pp)              { FactoryGirl.create :content_tag, value: 'os-practice-problems' }

  let!(:tasked_reading)  { FactoryGirl.create(:tasks_tasked_reading) }

  let!(:task)            { tasked_reading.task_step.task }

  let!(:tasking)         { FactoryGirl.create :tasks_tasking, task: task.entity_task }

  let!(:tasked_exercise) {
    te = FactoryGirl.build(:tasks_tasked_exercise)
    te.task_step.task = task
    te.save!
    te
  }

  let!(:tasked_exercise_with_recovery) {
    te = FactoryGirl.build(
      :tasks_tasked_exercise,
      content: OpenStax::Exercises::V1.fake_client.new_exercise_hash(tags: [lo.value]).to_json
    )
    te.task_step.task = task.reload
    te.task_step.can_be_recovered = true
    te.save!
    te
  }

  let!(:next_step)  { FactoryGirl.create(:tasks_task_step, task: task.reload) }

  let!(:related_exercise) { FactoryGirl.create(
    :content_exercise,
    page: tasked_exercise_with_recovery.exercise.page,
    content: OpenStax::Exercises::V1.fake_client
                                    .new_exercise_hash(
                                      tags: [lo.value, pp.value]
                                    ).to_json
  ) }
  let!(:related_tagging_1)   { FactoryGirl.create(
    :content_exercise_tag, exercise: tasked_exercise_with_recovery.exercise, tag: lo
  ) }
  let!(:related_tagging_2)   { FactoryGirl.create(
    :content_exercise_tag, exercise: related_exercise, tag: lo
  ) }
  let!(:related_tagging_3)   { FactoryGirl.create(
    :content_exercise_tag, exercise: related_exercise, tag: pp
  ) }

  let!(:pools) { Content::Routines::PopulateExercisePools[book: related_exercise.book] }

  it "cannot be called on task_steps where can_be_recovered is false" do
    result = nil
    expect {
      result = described_class.call(task_step: tasked_reading.task_step)
    }.not_to change{ tasked_reading.task_step }
    expect(result.errors.first.code).to eq(:related_exercise_not_available)

    result = nil
    expect {
      result = described_class.call(task_step: tasked_exercise.task_step)
    }.not_to change{ tasked_reading.task_step }
    expect(result.errors.first.code).to eq(:related_exercise_not_available)
  end

  it "adds a new exercise step after the given step" do
    result = nil
    related_exercise_step = nil
    task_step = tasked_exercise_with_recovery.task_step
    expect {
      result = described_class.call(
        task_step: tasked_exercise_with_recovery.task_step
      )
    }.to change{ related_exercise_step = task_step.reload.next_by_number }

    expect(result.errors).to be_empty
    expect(related_exercise_step).to eq result.outputs.related_exercise_step
    expect(related_exercise_step.group_type).to eq 'recovery_group'
    related_exercise_tasked = related_exercise_step.tasked
    expect(related_exercise_tasked.url).to eq related_exercise.url
    expect(related_exercise_tasked.title).to eq related_exercise.title
    expect(related_exercise_tasked.content).to eq related_exercise.content
    expect(next_step.reload.number).to eq related_exercise_step.number + 1
  end

end
