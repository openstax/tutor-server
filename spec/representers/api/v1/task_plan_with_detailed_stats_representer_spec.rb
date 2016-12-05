require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlanWithDetailedStatsRepresenter, type: :representer do

  let(:number_of_students) { 2 }

  let(:task_plan) {
    allow_any_instance_of(Tasks::Assistants::IReadingAssistant).to(
      receive(:k_ago_map) { [ [0, 2] ] }
    )
    allow_any_instance_of(Tasks::Assistants::IReadingAssistant).to(
      receive(:num_personalized_exercises_per_page) { 0 }
    )
    FactoryGirl.create :tasked_task_plan, number_of_students: number_of_students
  }

  let(:representation) { described_class.new(task_plan).as_json }

  it "represents a task plan's stats" do
    # Answer an exercise correctly and mark it as completed
    student_tasks = task_plan.tasks.joins(taskings: { role: :student })
    task_step = student_tasks.first.task_steps.select{ |ts| ts.tasked.exercise? }.first
    answer_ids = task_step.tasked.answer_ids
    correct_answer_id = task_step.tasked.correct_answer_id
    incorrect_answer_ids = (answer_ids - [correct_answer_id])
    task_step.tasked.free_response = 'a sentence explaining all the things'
    task_step.tasked.answer_id = correct_answer_id
    task_step.tasked.save!
    MarkTaskStepCompleted.call(task_step: task_step)

    # Answer an exercise incorrectly and mark it as completed
    task_step = student_tasks.last.task_steps.select{ |ts| ts.tasked.exercise? }.first
    task_step.tasked.free_response = 'a sentence not explaining anything'
    task_step.tasked.answer_id = incorrect_answer_ids.first
    task_step.tasked.save!
    MarkTaskStepCompleted.call(task_step: task_step)

    expect(representation.deep_symbolize_keys).to match(
      id: task_plan.id.to_s,
      title: task_plan.title,
      type: 'reading',
      stats: [
        {
          period_id: task_plan.owner.periods.first.id.to_s,
          name: '1st',
          mean_grade_percent: 50,
          total_count: 2,
          complete_count: 0,
          partially_complete_count: 2,
          current_pages: a_collection_containing_exactly(
            id: task_plan.settings['page_ids'].first.to_s,
            title: "Newton's First Law of Motion: Inertia",
            student_count: 2,
            correct_count: 1,
            incorrect_count: 1,
            chapter_section: [1, 1],
            is_trouble: false,
            exercises: a_collection_containing_exactly(
              {
                content: a_kind_of(String),
                question_stats: [{
                  question_id: a_kind_of(String),
                  answered_count: 2,
                  answers: a_collection_containing_exactly(
                    {
                      student_names: [ a_kind_of(String) ],
                      free_response: 'a sentence explaining all the things',
                      answer_id: correct_answer_id
                    },
                    {
                      student_names: [ a_kind_of(String) ],
                      free_response: 'a sentence not explaining anything',
                      answer_id: incorrect_answer_ids.first
                    }
                  ),
                  answer_stats: answer_ids.map do |aid|
                    {
                      answer_id: aid.to_s,
                      selected_count: (aid.to_s == correct_answer_id ||
                                       aid.to_s == incorrect_answer_ids.first) ? 1 : 0
                    }
                  end
                }],
                average_step_number: 3.0
              },
              {
                content: a_kind_of(String),
                question_stats: [{
                  question_id: a_kind_of(String),
                  answered_count: 0,
                  answers: [],
                  answer_stats: 4.times.map do
                    {
                      answer_id: a_kind_of(String),
                      selected_count: 0
                    }
                  end
                }],
                average_step_number: 5.0
              }
            )
          ),
          spaced_pages: a_collection_containing_exactly(
            id: task_plan.settings['page_ids'].first.to_s,
            title: "Newton's First Law of Motion: Inertia",
            student_count: 0,
            correct_count: 0,
            incorrect_count: 0,
            chapter_section: [1, 1],
            is_trouble: false,
            exercises: a_kind_of(Array)
          ),
          is_trouble: false
        }
      ]
    )
  end

end
