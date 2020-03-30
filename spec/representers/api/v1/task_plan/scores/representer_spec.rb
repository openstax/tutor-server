require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlan::Scores::Representer, type: :representer do
  let(:number_of_students) { 2 }

  let(:reading)   { FactoryBot.create :tasked_task_plan, number_of_students: number_of_students }
  let(:course)    { reading.owner }
  let(:task_plan) do
    reading_pages = Content::Models::Page.where(id: reading.settings['page_ids'])

    FactoryBot.create(
      :tasks_task_plan,
      type: :homework,
      owner: course,
      assistant_code_class_name: 'Tasks::Assistants::HomeworkAssistant',
      target: course.periods.first,
      settings: {
        page_ids: reading_pages.map(&:id).map(&:to_s),
        exercises: reading_pages.first.exercises.first(5).map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.num_questions }
        end,
        exercises_count_dynamic: 3
      }
    ).tap do |task_plan|
      task_plan.grading_template.update_attribute :late_work_penalty_applied, :immediately
    end
  end
  let(:student_tasks)        { task_plan.tasks.joins(taskings: { role: :student }).to_a }
  let(:students)             { student_tasks.map { |task| task.taskings.first.role.student } }
  let(:late_work_penalty)    { task_plan.grading_template.late_work_penalty }
  let(:late_work_multiplier) { 1.0 - late_work_penalty }

  let(:representation)       { described_class.new(task_plan).as_json.deep_symbolize_keys }

  context 'before the due date' do
    before { DistributeTasks.call task_plan: task_plan }

    it 'represents a task plan with tasks missing some work' do
      # Answer an exercise correctly and mark it as completed
      task_step = student_tasks.first.task_steps.filter { |ts| ts.tasked.exercise? }.first
      answer_ids = task_step.tasked.answer_ids
      correct_answer_id = task_step.tasked.correct_answer_id
      incorrect_answer_ids = (answer_ids - [correct_answer_id])
      task_step.tasked.free_response = 'a sentence explaining all the things'
      task_step.tasked.answer_id = correct_answer_id
      task_step.tasked.save!
      MarkTaskStepCompleted.call(task_step: task_step)

      # Answer an exercise incorrectly and mark it as completed
      task_step = student_tasks.last.task_steps.filter { |ts| ts.tasked.exercise? }.first
      task_step.tasked.free_response = 'a sentence not explaining anything'
      task_step.tasked.answer_id = incorrect_answer_ids.first
      task_step.tasked.save!
      MarkTaskStepCompleted.call(task_step: task_step)

      expect(representation).to include(
        id: task_plan.id.to_s,
        title: task_plan.title,
        type: 'homework',
        periods: [
          {
            id: task_plan.owner.periods.first.id.to_s,
            name: '1st',
            question_headings: 8.times.map do |index|
              { title: "Q#{index + 1}", type: index < 5 ? 'MCQ' : 'Tutor', points: 1.0 }
            end,
            late_work_fraction_penalty: late_work_penalty,
            num_questions_dropped: 0,
            points_dropped: 0.0,
            students: [
              {
                role_id: students.first.entity_role_id,
                first_name: students.first.first_name,
                last_name: students.first.last_name,
                is_dropped: false,
                is_late: false,
                available_points: 8.0,
                total_points: 1.0,
                total_fraction: 1.0,
                late_work_point_penalty: 0.0,
                late_work_fraction_penalty: 0.0,
                questions: [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: true,
                    free_response: 'a sentence explaining all the things',
                    selected_answer_id: kind_of(String),
                    points: 1.0
                  }
                ] + [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: false
                  }
                ] * 4 + [ { is_completed: false } ] * 3
              },
              {
                role_id: students.second.entity_role_id,
                first_name: students.second.first_name,
                last_name: students.second.last_name,
                is_dropped: false,
                is_late: false,
                available_points: 8.0,
                total_points: 0.0,
                total_fraction: 0.0,
                late_work_point_penalty: 0.0,
                late_work_fraction_penalty: 0.0,
                questions: [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: true,
                    free_response: 'a sentence not explaining anything',
                    selected_answer_id: kind_of(String),
                    points: 0.0
                  }
                ] + [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: false
                  }
                ] * 4 + [ { is_completed: false } ] * 3
              }
            ].sort_by { |student| [ student[:last_name], student[:first_name] ] }
          }
        ]
      )
    end
  end

  context 'after the due date' do
    before do
      task_plan.tasking_plans.each do |tasking_plan|
        tasking_plan.opens_at = Time.current - 1.day
        tasking_plan.due_at = Time.current - 1.day
        tasking_plan.save!
      end

      DistributeTasks.call task_plan: task_plan
    end

    it 'represents a task plan with late tasks' do
      # Answer an exercise correctly and mark it as completed
      task_step = student_tasks.first.task_steps.filter { |ts| ts.tasked.exercise? }.first
      answer_ids = task_step.tasked.answer_ids
      correct_answer_id = task_step.tasked.correct_answer_id
      incorrect_answer_ids = (answer_ids - [correct_answer_id])
      task_step.tasked.free_response = 'a sentence explaining all the things'
      task_step.tasked.answer_id = correct_answer_id
      task_step.tasked.save!
      MarkTaskStepCompleted.call(task_step: task_step)

      # Answer an exercise incorrectly and mark it as completed
      task_step = student_tasks.last.task_steps.filter { |ts| ts.tasked.exercise? }.first
      task_step.tasked.free_response = 'a sentence not explaining anything'
      task_step.tasked.answer_id = incorrect_answer_ids.first
      task_step.tasked.save!
      MarkTaskStepCompleted.call(task_step: task_step)

      expect(representation).to include(
        id: task_plan.id.to_s,
        title: task_plan.title,
        type: 'homework',
        periods: [
          {
            id: task_plan.owner.periods.first.id.to_s,
            name: '1st',
            question_headings: 8.times.map do |index|
              { title: "Q#{index + 1}", type: index < 5 ? 'MCQ' : 'Tutor', points: 1.0 }
            end,
            late_work_fraction_penalty: late_work_penalty,
            num_questions_dropped: 0,
            points_dropped: 0.0,
            students: [
              {
                role_id: students.first.entity_role_id,
                first_name: students.first.first_name,
                last_name: students.first.last_name,
                is_dropped: false,
                is_late: true,
                available_points: 8.0,
                total_points: 1.0 * late_work_multiplier,
                total_fraction: 0.125 * late_work_multiplier,
                late_work_point_penalty: 1.0 * late_work_penalty,
                late_work_fraction_penalty: late_work_penalty,
                questions: [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: true,
                    free_response: 'a sentence explaining all the things',
                    selected_answer_id: kind_of(String),
                    points: 1.0
                  }
                ] + [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: false,
                    points: 0.0
                  }
                ] * 4 + [ { is_completed: false, points: 0.0 } ] * 3
              },
              {
                role_id: students.second.entity_role_id,
                first_name: students.second.first_name,
                last_name: students.second.last_name,
                is_dropped: false,
                is_late: true,
                available_points: 8.0,
                total_points: 0.0,
                total_fraction: 0.0,
                late_work_point_penalty: 0.0,
                late_work_fraction_penalty: late_work_penalty,
                questions: [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: true,
                    free_response: 'a sentence not explaining anything',
                    selected_answer_id: kind_of(String),
                    points: 0.0
                  }
                ] + [
                  {
                    id: kind_of(String),
                    exercise_id: kind_of(String),
                    is_completed: false,
                    points: 0.0
                  }
                ] * 4 + [ { is_completed: false, points: 0.0 } ] * 3
              }
            ].sort_by { |student| [ student[:last_name], student[:first_name] ] }
          }
        ]
      )
    end
  end
end
