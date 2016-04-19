require 'rails_helper'

RSpec.describe TaskExercise, type: :routine do
  let!(:exercise)  do
    content_exercise = FactoryGirl.create(:content_exercise)
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end

  let!(:multipart_exercise)  do
    content_exercise = FactoryGirl.create(:content_exercise, num_parts: 2)
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end

  let!(:task_step) { FactoryGirl.build(:tasks_task_step) }

  it 'builds a TaskedExercise for the given exercise and task_step (and saves when task saved)' do
    TaskExercise[exercise: exercise, task_step: task_step]
    expect(task_step.tasked).to be_a(Tasks::Models::TaskedExercise)
    expect(task_step.tasked).to be_persisted
    expect(task_step.tasked.is_in_multipart).to be_falsy
    expect(task_step.tasked.question_id).to be_kind_of(String)
    expect(task_step.tasked.task_step).to eq task_step
    parser = task_step.tasked.parser
    expect(parser.url).to eq exercise.url
    expect(parser.title).to eq exercise.title
    expect(parser.content).to eq exercise.content
  end

  it 'builds two TaskedExercises for a multipart' do
    task = task_step.task

    TaskExercise[exercise: multipart_exercise, task_step: task_step, task: task]

    expect(task.task_steps.length).to eq 2
    expect(task.task_steps.first).to eq task_step

    expect(task.task_steps[0].tasked.is_in_multipart).to be_truthy
    expect(task.task_steps[1].tasked.is_in_multipart).to be_truthy

    expect(task.task_steps[0].tasked.content).to match("(0)")
    expect(task.task_steps[1].tasked.content).to match("(1)")
  end

end
