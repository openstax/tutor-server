require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlan::Scores::Representer, type: :representer do
  let(:number_of_students) { 2 }

  let(:task_plan)          do
    FactoryBot.create :tasked_task_plan, number_of_students: number_of_students
  end

  let(:representation)     { described_class.new(task_plan).as_json.deep_symbolize_keys }

  it 'represents a task plan with scores' do
    # Answer an exercise correctly and mark it as completed
    student_tasks = task_plan.tasks.joins(taskings: { role: :student })
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
          data_headings: [],
          available_points: [],
          questions_dropped: 0,
          points_dropped: 0.0,
          students: [],
          average_score: []
        }
      ]
    )
  end
end
