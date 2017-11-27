require 'rails_helper'
require 'database_cleaner'

RSpec.describe 'exercises:remove', type: :rake do
  include_context 'rake'

  before(:all) do
    # Each tasked TP has its own ecosystem and course and some number of students
    task_plan_1 = FactoryBot.create :tasked_task_plan, number_of_students: 2
    task_plan_2 = FactoryBot.create :tasked_task_plan, number_of_students: 1
    @tasks = task_plan_1.tasks + task_plan_2.tasks
    @tasks.each do |task|
      Preview::AnswerExercise.call(
        task_step: task.tasked_exercises.first.task_step, is_correct: true
      )

      task.reload
    end
  end

  let(:uid)       { @tasks.first.tasked_exercises.first.exercise.uid }
  let(:num_tasks) { @tasks.size }

  it 'removes the given exercises from the assignments, scores and caches' do
    expect(Tasks::UpdateTaskCaches).to receive(:perform_later).exactly(num_tasks).times

    expect do
      call(uid)

      @tasks.each(&:reload)
    end.to change { Tasks::Models::TaskedExercise.count }.by(-num_tasks)
       .and change { Tasks::Models::TaskStep.count }.by(-num_tasks)
       .and not_change { Tasks::Models::Task.count }
       .and change { @tasks.map(&:steps_count).reduce(0, :+) }.by(-num_tasks)
       .and change { @tasks.map(&:completed_steps_count).reduce(0, :+) }.by(-num_tasks)
       .and change { @tasks.map(&:exercise_steps_count).reduce(0, :+) }.by(-num_tasks)
       .and change { @tasks.map(&:completed_exercise_steps_count).reduce(0, :+) }.by(-num_tasks)
       .and change { @tasks.map(&:correct_exercise_steps_count).reduce(0, :+) }.by(-num_tasks)

    @tasks.each { |task| expect(task.tasked_exercises.first.exercise.uid).not_to eq uid }
  end
end
