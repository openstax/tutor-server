require 'rails_helper'

RSpec.describe Tasks::PlaceholderStrategies::HomeworkPersonalized, type: :placeholder_strategy do
  let(:strategy)       { described_class.new }
  let(:step_types)     { [:tasks_tasked_exercise] * 2 + [:tasks_tasked_placeholder] * 2 }

  let(:period)         { FactoryGirl.create :course_membership_period }

  let(:user)           { FactoryGirl.create :user }
  let(:taskee_role)    { AddUserAsPeriodStudent[user: user, period: period] }

  let(:pool)           { FactoryGirl.create :content_pool }
  let(:page)           { FactoryGirl.create :content_page, homework_dynamic_pool: pool }
  let(:pool_exercises) do
    2.times.map{ FactoryGirl.create :content_exercise, page: page }.tap do |exercises|
      pool.update_attribute(:content_exercise_ids, exercises.map(&:id))
    end
  end

  let(:task_plan) do
    FactoryGirl.create :tasks_task_plan, type: :homework,
                                         owner: period.course,
                                         ecosystem: page.ecosystem
  end

  let(:task)     do
    FactoryGirl.create(:tasks_task, task_plan: task_plan, task_type: :homework,
                       step_types: step_types, tasked_to: [taskee_role],
                       personalized_placeholder_strategy: strategy).tap do |task|
      task.update_step_counts!
      exercises = task.tasked_exercises.map(&:exercise)
      exercises.each{ |ex| ex.update_attribute(:page, page) }
      task_plan.update_attribute(:settings, { 'exercise_ids' => exercises.map{ |ex| ex.id.to_s } })
    end
  end

  it 'replaces Placeholder steps with Exercise steps from the page\'s reading_dynamic_pool' do
    expect(OpenStax::Biglearn::Api).to(
      receive(:fetch_assignment_pes).and_return(pool_exercises).once
    )

    expect(task.exercise_steps_count).to eq 2
    expect(task.placeholder_steps_count).to eq 2

    strategy.populate_placeholders(task: task)
    task.update_step_counts!

    expect(task.exercise_steps_count).to eq 4
    expect(task.placeholder_steps_count).to eq 0

    new_exercises = task.exercise_steps.last(2).map{ |step| step.tasked.exercise }
    expect(Set.new new_exercises).to eq Set.new pool_exercises
  end

  it 'removes all Placeholder steps even if not enough Exercises available' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return([]).once

    expect(task.exercise_steps_count).to eq 2
    expect(task.placeholder_steps_count).to eq 2

    strategy.populate_placeholders(task: task)
    task.update_step_counts!

    expect(task.exercise_steps_count).to eq 2
    expect(task.placeholder_steps_count).to eq 0
  end

  it 'does not blow up if placeholder steps have been marked as completed' do
    task.task_steps.each{ |ts| ts.complete.save! }

    expect(OpenStax::Biglearn::Api).to(
      receive(:fetch_assignment_pes).and_return(pool_exercises).once
    )

    expect(task.exercise_steps_count).to eq 2
    expect(task.placeholder_steps_count).to eq 2

    strategy.populate_placeholders(task: task)
    task.update_step_counts!

    expect(task.exercise_steps_count).to eq 4
    expect(task.placeholder_steps_count).to eq 0

    new_exercises = task.exercise_steps.last(2).map{ |step| step.tasked.exercise }
    expect(Set.new new_exercises).to eq Set.new pool_exercises
  end
end
