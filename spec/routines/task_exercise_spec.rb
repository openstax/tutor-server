require 'rails_helper'

RSpec.describe TaskExercise, type: :routine do
  let!(:exercise)  do
    content_exercise = FactoryGirl.create(:content_exercise)
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end
  let!(:task_step) { FactoryGirl.build(:tasks_task_step) }

  it 'builds a TaskedExercise for the given exercise and task_step (and saves when task saved)' do
    TaskExercise[exercise: exercise, task_step: task_step]
    expect(task_step.tasked).to be_a(Tasks::Models::TaskedExercise)
    expect(task_step.tasked).to be_persisted
    expect(task_step.tasked.task_step).to eq task_step
    parser = task_step.tasked.parser
    expect(parser.url).to eq exercise.url
    expect(parser.title).to eq exercise.title
    expect(parser.content).to eq exercise.content
  end
end
