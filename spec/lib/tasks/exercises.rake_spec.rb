require 'rails_helper'
require 'database_cleaner'

RSpec.describe 'exercises:remove', type: :rake do
  include_context 'rake'

  let(:ecosystem) { FactoryBot.create :mini_ecosystem }

  before do
    # Each tasked TP has its own ecosystem and course and some number of students
    task_plan_1 = FactoryBot.create :tasked_task_plan,
      type: :homework,
      number_of_exercises_per_page: 1,
      ecosystem: ecosystem,
      number_of_students: 2
    task_plan_2 = FactoryBot.create :tasked_task_plan,
      type: :homework,
      settings: task_plan_1.settings,
      ecosystem: ecosystem,
      number_of_students: 1
    @tasks = task_plan_1.tasks + task_plan_2.tasks
    @tasks.each do |task|
      Preview::AnswerExercise.call(
        task_step: task.tasked_exercises.first.task_step, is_correct: true
      )

      task.reload
    end
  end

  let(:uid)            { @tasks.first.tasked_exercises.first.exercise.uid }
  let(:num_tasks)      { 3 }
  let(:queue)          { :dashboard }
  let(:configured_job) { Lev::ActiveJob::ConfiguredJob.new(Tasks::UpdateTaskCaches, queue: queue) }

  before do
    allow(Tasks::UpdateTaskCaches).to receive(:set) do |options|
      expect(options[:queue]).to eq queue
      configured_job
    end
  end

  it 'removes the given exercises from the assignments, scores and caches' do
    expect(configured_job).to receive(:perform_later).at_least(:once).and_call_original

    expect do
      call(uid)

      @tasks.each(&:reload)
    end.to change { Tasks::Models::TaskedExercise.count }.by(-num_tasks)
       .and change { Tasks::Models::TaskStep.count }.by(-num_tasks)
       .and not_change { Tasks::Models::Task.count }
       .and change { @tasks.sum(&:steps_count) }.by(-num_tasks)
       .and change { @tasks.sum(&:completed_steps_count) }.by(-num_tasks)
       .and change { @tasks.sum(&:exercise_steps_count) }.by(-num_tasks)
       .and change { @tasks.sum(&:completed_exercise_steps_count) }.by(-num_tasks)
       .and change { @tasks.sum(&:correct_exercise_steps_count) }.by(-num_tasks)

    @tasks.each { |task| expect(task.tasked_exercises.first.exercise.uid).not_to eq uid }
  end
end
