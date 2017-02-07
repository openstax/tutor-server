require 'rails_helper'

RSpec.describe GetHistory, type: :routine, speed: :slow do
  before(:all) do
    homework_assistant = FactoryGirl.create(
      :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
    )

    period = FactoryGirl.create :course_membership_period
    course = period.course

    user = FactoryGirl.create :user

    @role = AddUserAsPeriodStudent[user: user, period: period]

    reading_plan_1 = FactoryGirl.create(:tasked_task_plan, owner: course)
    page_ids_1 = reading_plan_1.settings['page_ids']
    pages_1 = Content::Models::Page.where(id: page_ids_1).to_a
    homework_exercises_1 = pages_1.flat_map(&:exercises).sort_by(&:uid).first(5)
    homework_plan_1 = FactoryGirl.create(
      :tasked_task_plan, owner: course,
                         type: 'homework',
                         assistant: homework_assistant,
                         ecosystem: pages_1.first.ecosystem,
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
                         ecosystem: pages_2.first.ecosystem,
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
                         ecosystem: pages_3.first.ecosystem,
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

  let(:correct_total_count)   { correct_tasks.size }

  let(:correct_ecosystem_ids) { correct_tasks.map{ |task| task.task_plan.content_ecosystem_id } }

  let(:correct_core_page_ids) do
    correct_tasks.map do |task|
      case task.task_type.to_sym
      when :reading
        task.task_plan.settings['page_ids'].compact.map(&:to_i)
      when :homework
        exercise_ids = task.task_plan.settings['exercise_ids'].compact.map(&:to_i)
        Content::Models::Exercise.where(id: exercise_ids).map(&:content_page_id).uniq
      when :concept_coach
        [task.concept_coach_task.content_page_id]
      else
        task.tasked_exercises.map{ |te| te.exercise.content_page_id }.uniq
      end
    end
  end

  let(:correct_exercise_number_sets) do
    correct_tasks.map{ |task| Set.new task.tasked_exercises.map{ |te| te.exercise.number } }
  end

  context "when there are more than #{GetHistory::TASK_BATCH_SIZE} tasks" do
    before do
      ecosystem = FactoryGirl.create :content_ecosystem

      tasks = GetHistory::TASK_BATCH_SIZE.times.map do |index|
        task = Tasks::Models::Task.new(
          title: "Task #{index + 1}",
          task_type: :extra,
          ecosystem: ecosystem
        )
        task.taskings = [Tasks::Models::Tasking.new(task: task, role: @role)]
        task
      end

      Tasks::Models::Task.import tasks, recursive: true, validate: false
    end

    it 'returns the correct number of tasks' do
      history = described_class.call(roles: @role, type: :all).outputs.history[@role]
      expect(history.total_count).to eq GetHistory::TASK_BATCH_SIZE + 6
    end
  end

  context 'when creating a new reading task' do
    context 'when all tasks have dynamic reading exercises' do
      let(:correct_tasks) { [@reading_task_3, @reading_task_2, @reading_task_1] }

      it 'returns all reading tasks in history' do
        history = described_class.call(roles: @role, type: :reading).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
      end
    end

    context 'when some tasks don\'t have dynamic reading exercises' do
      let(:correct_tasks) { [@reading_task_2, @reading_task_1] }

      before(:each) do
        @reading_task_3.reload.tasked_exercises.map{ |te| te.exercise.page }.uniq.each do |page|
          page.reading_dynamic_pool.update_attribute(:content_exercise_ids, [])
        end
      end

      it 'does only reading tasks with dynamic reading exercises' do
        history = described_class.call(roles: @role, type: :reading).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
      end
    end
  end

  context 'when creating a new homework task' do
    let(:correct_tasks) { [@homework_task_3, @homework_task_2, @homework_task_1] }

    it 'returns all homework tasks in history' do
        history = described_class.call(roles: @role, type: :homework).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
    end
  end

  context 'when creating a new practice task' do
    context 'when all reading tasks have dynamic reading exercises' do
      let(:correct_tasks) { [@homework_task_3, @reading_task_3, @homework_task_2,
                             @reading_task_2, @homework_task_1, @reading_task_1] }

      it 'returns all tasks in history' do
        history = described_class.call(roles: @role, type: :all).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
      end
    end

    context 'when some reading tasks don\'t have dynamic reading exercises' do
      let(:correct_tasks) { [@homework_task_3, @reading_task_3, @homework_task_2,
                             @reading_task_2, @homework_task_1, @reading_task_1] }

      before(:each) do
        @reading_task_3.reload.tasked_exercises.map{ |te| te.exercise.page }.uniq.each do |page|
          page.reading_dynamic_pool.update_attribute(:content_exercise_ids, [])
        end
      end

      it 'returns all tasks in history' do
        history = described_class.call(roles: @role, type: :all).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
      end
    end
  end

  context 'when creating a "try another" step' do
    context 'when all reading tasks have dynamic reading exercises' do
      let(:correct_tasks) { [@homework_task_3, @reading_task_3, @homework_task_2,
                             @reading_task_2, @homework_task_1, @reading_task_1] }

      it 'returns all tasks in history' do
        history = described_class.call(roles: @role, type: :all).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
      end
    end

    context 'when some reading tasks don\'t have dynamic reading exercises' do
      let(:correct_tasks) { [@homework_task_3, @reading_task_3, @homework_task_2,
                             @reading_task_2, @homework_task_1, @reading_task_1] }

      before(:each) do
        @reading_task_3.reload.tasked_exercises.map{ |te| te.exercise.page }.uniq.each do |page|
          page.reading_dynamic_pool.update_attribute(:content_exercise_ids, [])
        end
      end

      it 'returns all tasks in history' do
        history = described_class.call(roles: @role, type: :all).outputs.history[@role]
        expect(history.total_count).to eq correct_total_count
        expect(history.ecosystem_ids).to eq correct_ecosystem_ids
        expect(history.core_page_ids).to eq correct_core_page_ids
        history_exercise_number_sets = history.exercise_numbers.map{ |numbers| Set.new numbers }
        expect(history_exercise_number_sets).to eq correct_exercise_number_sets
      end
    end
  end
end
