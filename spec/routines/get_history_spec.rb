require 'rails_helper'

describe GetHistory, type: :routine do
  before(:all) do
    DatabaseCleaner.start

    homework_assistant = FactoryGirl.create(
          :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
    )

    period = FactoryGirl.create :course_membership_period
    course = period.course

    profile = FactoryGirl.create :user_profile
    strategy = User::Strategies::Direct::User.new(profile)
    user = User::User.new(strategy: strategy)

    @role = AddUserAsPeriodStudent[user: user, period: period]

    reading_plan_1 = FactoryGirl.create(:tasked_task_plan, owner: course)
    page_ids_1 = reading_plan_1.settings['page_ids']
    pages_1 = Content::Models::Page.where(id: page_ids_1).to_a
    homework_exercises_1 = pages_1.flat_map(&:exercises).sort_by(&:uid).first(5)
    homework_plan_1 = FactoryGirl.create(
      :tasked_task_plan, owner: course,
                         type: 'homework',
                         assistant: homework_assistant,
                         settings: { 'exercise_ids' => homework_exercises_1.map{ |ex| ex.id.to_s },
                                     'exercises_count_dynamic' => 2 }
    )

    reading_plan_2 = FactoryGirl.create(:tasked_task_plan, owner: course)
    page_ids_2 = reading_plan_2.settings['page_ids']
    pages_2 = Content::Models::Page.where(id: page_ids_2).to_a
    homework_exercises_2 = pages_2.flat_map(&:exercises).sort_by(&:uid).first(4)
    homework_plan_2 = FactoryGirl.create(
      :tasked_task_plan, owner: course,
                         type: 'homework',
                         assistant: homework_assistant,
                         settings: { 'exercise_ids' => homework_exercises_2.map{ |ex| ex.id.to_s },
                                     'exercises_count_dynamic' => 3 }
    )

    reading_plan_3 = FactoryGirl.create(:tasked_task_plan, owner: course)
    page_ids_3 = reading_plan_3.settings['page_ids']
    pages_3 = Content::Models::Page.where(id: page_ids_3).to_a
    homework_exercises_3 = pages_3.flat_map(&:exercises).sort_by(&:uid).first(3)
    homework_plan_3 = FactoryGirl.create(
      :tasked_task_plan, owner: course,
                         type: 'homework',
                         assistant: homework_assistant,
                         settings: { 'exercise_ids' => homework_exercises_3.map{ |ex| ex.id.to_s },
                                     'exercises_count_dynamic' => 4 }
    )

    @reading_task_1 = reading_plan_1.tasks.joins(:taskings)
                                          .find_by(taskings: {entity_role_id: @role.id})
    @reading_task_2 = reading_plan_2.tasks.joins(:taskings)
                                          .find_by(taskings: {entity_role_id: @role.id})
    @reading_task_3 = reading_plan_3.tasks.joins(:taskings)
                                          .find_by(taskings: {entity_role_id: @role.id})
    @homework_task_1 = homework_plan_1.tasks.joins(:taskings)
                                            .find_by(taskings: {entity_role_id: @role.id})
    @homework_task_2 = homework_plan_2.tasks.joins(:taskings)
                                            .find_by(taskings: {entity_role_id: @role.id})
    @homework_task_3 = homework_plan_3.tasks.joins(:taskings)
                                            .find_by(taskings: {entity_role_id: @role.id})
  end

  after(:all) { DatabaseCleaner.clean }

  let(:correct_ecosystems) do
    correct_tasks.collect do |task|
      model = task.task_plan.ecosystem
      strategy = Content::Strategies::Direct::Ecosystem.new(model)
      Content::Ecosystem.new(strategy: strategy)
    end
  end

  let(:correct_exercise_sets)  do
    correct_tasks.collect do |task|
      Set.new task.tasked_exercises.collect do |te|
        model = te.exercise
        strategy = Content::Strategies::Direct::Exercise.new(model)
        Content::Exercise.new(strategy: strategy)
      end
    end
  end

  context 'when creating a new reading task' do
    let(:new_task)           { FactoryGirl.build :tasks_task, tasked_to: @role  }
    let(:correct_tasks)      { [new_task, @reading_task_3, @reading_task_2, @reading_task_1] }

    it 'returns the correct history' do
      history = described_class.call(role: @role, type: :reading, current_task: new_task).outputs
      expect(history.tasks).to eq correct_tasks
      expect(history.ecosystems).to eq correct_ecosystems
      history_exercise_sets = history.exercises.collect{ |exercises| Set.new exercises }
      expect(history_exercise_sets).to eq correct_exercise_sets
    end
  end

  context 'when creating a new homework task' do
    let(:new_task)           { FactoryGirl.build :tasks_task, tasked_to: @role,
                                                              task_type: :homework  }
    let(:correct_tasks)      { [new_task, @homework_task_3, @homework_task_2, @homework_task_1] }

    it 'returns the correct history' do
      history = described_class.call(role: @role, type: :homework, current_task: new_task).outputs
      expect(history.tasks).to eq correct_tasks
      expect(history.ecosystems).to eq correct_ecosystems
      history_exercise_sets = history.exercises.collect{ |exercises| Set.new exercises }
      expect(history_exercise_sets).to eq correct_exercise_sets
    end
  end

  context 'when creating a new practice task' do
    let(:new_task)           { FactoryGirl.build :tasks_task, tasked_to: @role,
                                                              task_type: :mixed_practice  }
    let(:correct_tasks)      { [new_task, @homework_task_3, @reading_task_3, @homework_task_2,
                                @reading_task_2, @homework_task_1, @reading_task_1] }

    it 'returns the correct history' do
      history = described_class.call(role: @role, type: :all, current_task: new_task).outputs
      expect(history.tasks).to eq correct_tasks
      expect(history.ecosystems).to eq correct_ecosystems
      history_exercise_sets = history.exercises.collect{ |exercises| Set.new exercises }
      expect(history_exercise_sets).to eq correct_exercise_sets
    end
  end

  context 'when creating a "try another" step' do
    let(:correct_tasks)      { [@homework_task_3, @reading_task_3, @homework_task_2,
                                @reading_task_2, @homework_task_1, @reading_task_1] }

    it 'returns the correct history' do
      history = described_class.call(role: @role, type: :all).outputs
      expect(history.tasks).to eq correct_tasks
      expect(history.ecosystems).to eq correct_ecosystems
      history_exercise_sets = history.exercises.collect{ |exercises| Set.new exercises }
      expect(history_exercise_sets).to eq correct_exercise_sets
    end
  end
end
