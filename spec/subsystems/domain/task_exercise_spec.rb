require 'rails_helper'

RSpec.describe Domain::TaskExercise do
  let!(:exercise)  { FactoryGirl.create(:content_exercise) }
  let!(:task_step) { FactoryGirl.build(:tasks_task_step) }

  it 'builds but does not save a TaskedExercise for the given exercise and task_step' do
    tasked_exercise = Domain::TaskExercise[exercise: exercise,
                                           can_be_recovered: true,
                                           task_step: task_step]
    expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
    expect(tasked_exercise).not_to be_persisted
    expect(tasked_exercise.can_be_recovered).to eq true
    expect(tasked_exercise.task_step).to eq task_step
    expect(tasked_exercise.exercise).to eq exercise
    expect(tasked_exercise.url).to eq exercise.url
    expect(tasked_exercise.title).to eq exercise.title
    expect(tasked_exercise.content).to eq exercise.content
  end
end
