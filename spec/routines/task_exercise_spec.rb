require 'rails_helper'

RSpec.describe TaskExercise, type: :routine do
  let!(:exercise)  do
    content_exercise = FactoryGirl.create(:content_exercise)
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end
  let!(:task_step) { FactoryGirl.build(:tasks_task_step) }

  it 'builds but does not save a TaskedExercise for the given exercise and task_step' do
    tasked_exercise = TaskExercise[exercise: exercise, task_step: task_step]
    expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
    expect(tasked_exercise).not_to be_persisted
    expect(tasked_exercise.task_step).to eq task_step
    parser = tasked_exercise.parser
    expect(parser.url).to eq exercise.url
    expect(parser.title).to eq exercise.title
    expect(parser.content).to eq exercise.content
  end
end
