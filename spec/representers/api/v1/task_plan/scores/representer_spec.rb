require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlan::Scores::Representer, type: :representer do
  let(:number_of_students) { 2 }

  let(:task_plan)          do
    FactoryBot.create :tasked_task_plan, number_of_students: number_of_students
  end
  let(:student_tasks)      { task_plan.tasks.joins(taskings: { role: :student }).to_a }
  let(:students)           { student_tasks.map { |task| task.taskings.first.role.student } }
  let(:late_work_penalty)  { task_plan.grading_template.late_work_penalty }

  let(:representation)     { described_class.new(task_plan).as_json.deep_symbolize_keys }

  it 'represents a task plan with scores' do
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
      type: 'reading',
      periods: [
        {
          id: task_plan.owner.periods.first.id.to_s,
          name: '1st',
          question_headings: 8.times.map { |idx| { title: "Q#{idx + 1}", type: 'MCQ' } },
          late_work_fraction_penalty: late_work_penalty,
          available_points: {
            name: 'Available Points',
            total_points: 8.0,
            total_fraction: 1.0,
            points_per_question: [ 1.0 ] * 8
          },
          num_questions_dropped: 0,
          points_dropped: 0.0,
          students: [
            {
              name: students.first.name,
              first_name: students.first.first_name,
              last_name: students.first.last_name,
              is_dropped: false,
              available_points: 8.0,
              total_points: 1.0 - late_work_penalty,
              total_fraction: (1.0 - late_work_penalty)/8,
              late_work_point_penalty: late_work_penalty,
              late_work_fraction_penalty: late_work_penalty,
              points_per_question: [ 1.0 ] + [ nil ] * 7
            },
            {
              name: students.second.name,
              first_name: students.second.first_name,
              last_name: students.second.last_name,
              is_dropped: false,
              available_points: 8.0,
              total_points: 0.0,
              total_fraction: 0.0,
              late_work_point_penalty: 0.0,
              late_work_fraction_penalty: late_work_penalty,
              points_per_question: [ 0.0 ] + [ nil ] * 7
            }
          ].sort_by { |student| [ student[:last_name], student[:first_name] ] },
          average_score: {
            name: 'Average Score',
            total_points: (1.0 - late_work_penalty)/2,
            total_fraction: (1.0 - late_work_penalty)/16,
            points_per_question: [ 0.5 ] + [ nil ] * 7
          }
        }
      ]
    )
  end
end
