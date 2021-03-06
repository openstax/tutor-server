require 'rails_helper'

RSpec.describe GetTaskCorePageIds, type: :routine do
  before do
    homework_assistant = FactoryBot.create(
      :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
    )

    period = FactoryBot.create :course_membership_period
    course = period.course

    user = FactoryBot.create :user_profile

    @role = AddUserAsPeriodStudent[user: user, period: period]

    reading_plan_1 = FactoryBot.create(:tasked_task_plan, course: course, number_of_students: 0)
    @page_ids_1 = reading_plan_1.core_page_ids.map(&:to_i)
    pages_1 = Content::Models::Page.where(id: @page_ids_1).to_a
    homework_exercises_1 = pages_1.flat_map(&:exercises).sort_by(&:uid).first(5)
    homework_plan_1 = FactoryBot.create(
      :tasked_task_plan,
      course: course,
      type: :homework,
      assistant: homework_assistant,
      ecosystem: pages_1.first.ecosystem,
      number_of_students: 0,
      settings: {
        exercises: homework_exercises_1.map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 2
      }
    )

    reading_plan_2 = FactoryBot.create(:tasked_task_plan, course: course, number_of_students: 0)
    @page_ids_2 = reading_plan_2.core_page_ids.map(&:to_i)
    pages_2 = Content::Models::Page.where(id: @page_ids_2).to_a
    homework_exercises_2 = pages_2.flat_map(&:exercises).sort_by(&:uid).first(4)
    homework_plan_2 = FactoryBot.create(
      :tasked_task_plan,
      course: course,
      type: :homework,
      assistant: homework_assistant,
      ecosystem: pages_2.first.ecosystem,
      number_of_students: 0,
      settings: {
        exercises: homework_exercises_2.map do |exercise|
            { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 3
      }
    )

    reading_plan_3 = FactoryBot.create(:tasked_task_plan, course: course, number_of_students: 0)
    @page_ids_3 = reading_plan_3.core_page_ids.map(&:to_i)
    pages_3 = Content::Models::Page.where(id: @page_ids_3).to_a
    homework_exercises_3 = pages_3.flat_map(&:exercises).sort_by(&:uid).first(3)
    homework_plan_3 = FactoryBot.create(
      :tasked_task_plan,
      course: course,
      type: :homework,
      assistant: homework_assistant,
      ecosystem: pages_3.first.ecosystem,
      number_of_students: 0,
      settings: {
        exercises: homework_exercises_3.map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 4
      }
    )

    @reading_task_1 = reading_plan_1.tasks.joins(:taskings)
                                          .find_by(taskings: { entity_role_id: @role.id })
    @reading_task_2 = reading_plan_2.tasks.joins(:taskings)
                                          .find_by(taskings: { entity_role_id: @role.id })
    @reading_task_3 = reading_plan_3.tasks.joins(:taskings)
                                          .find_by(taskings: { entity_role_id: @role.id })
    @homework_task_1 = homework_plan_1.tasks.joins(:taskings)
                                            .find_by(taskings: { entity_role_id: @role.id })
    @homework_task_2 = homework_plan_2.tasks.joins(:taskings)
                                            .find_by(taskings: { entity_role_id: @role.id })
    @homework_task_3 = homework_plan_3.tasks.joins(:taskings)
                                            .find_by(taskings: { entity_role_id: @role.id })
  end

  let(:tasks) {
    [@reading_task_1,   @reading_task_2,    @reading_task_3,
     @homework_task_1,  @homework_task_2,  @homework_task_3]
  }

  it 'returns the correct core_page_ids for all tasks' do
    task_id_to_core_page_ids_map = described_class[tasks: tasks]

    tasks.each do |task|
      plan = task.task_plan
      page_ids = if plan.homework?
                   plan.settings['exercises'].map do |exercise|
                     Content::Models::Exercise.find(exercise['id']).page.id
                   end.uniq
                 else
                   task.task_plan.settings['page_ids'].map(&:to_i)
                 end
      expect(task_id_to_core_page_ids_map[task.id.to_s]).to eq page_ids
    end
  end
end
