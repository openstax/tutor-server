require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlanWithDetailedStatsRepresenter, :type => :representer,
                                                              :vcr => VCR_OPTS do

  let!(:number_of_students){ 2 }

  let!(:task_plan) {
    allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [ [0, 2] ] }
    FactoryGirl.create :tasked_task_plan, number_of_students: number_of_students
  }

  it "represents a task plan's stats" do
    # Answer an exercise correctly and mark it as completed
    task_step = task_plan.tasks.first.task_steps
                         .select{ |ts| ts.tasked.exercise? }.first
    answer_ids = task_step.tasked.answer_ids
    correct_answer_id = task_step.tasked.correct_answer_id
    incorrect_answer_ids = (answer_ids - [correct_answer_id])
    task_step.tasked.free_response = "a sentence explaining all the things"
    task_step.tasked.answer_id = correct_answer_id
    task_step.tasked.save!
    MarkTaskStepCompleted.call(task_step: task_step)

    # Answer an exercise incorrectly and mark it as completed
    task_step = task_plan.tasks.last.task_steps
                         .select{ |ts| ts.tasked.exercise? }.first
    task_step.tasked.free_response = "a sentence not explaining anything"
    task_step.tasked.answer_id = incorrect_answer_ids.first
    task_step.tasked.save!
    MarkTaskStepCompleted.call(task_step: task_step)

    representation = Api::V1::TaskPlanWithDetailedStatsRepresenter.new(task_plan).as_json
    expect(representation).to include(
      "id" => task_plan.id.to_s,
      "type" => "reading",
      "stats" => {
        "course" => {
          "mean_grade_percent"       => 50,
          "total_count"              => 2,
          "complete_count"           => 0,
          "partially_complete_count" => 2,
          "current_pages"            => a_collection_containing_exactly(
            "id"     => task_plan.settings['page_ids'].first.to_s,
            "title"  => "Force",
            "student_count"   => 2,
            "correct_count"   => 1,
            "incorrect_count" => 1,
            "exercises" => a_collection_containing_exactly(
              "content_json" => a_kind_of(String),
              "answered_count" => 2,
              "answers" => a_collection_containing_exactly(
                { "id" => correct_answer_id.to_s, "selected_count" => 1 },
                { "id" => incorrect_answer_ids.first.to_s, "selected_count" => 1 },
                { "id" => incorrect_answer_ids.second.to_s, "selected_count" => 0 },
                { "id" => incorrect_answer_ids.third.to_s, "selected_count" => 0 }
              )
            )
          ),
          "spaced_pages" => a_collection_containing_exactly(
            "id"     => task_plan.settings['page_ids'].first.to_s,
            "title"  => "Force",
            "student_count"   => 2,
            "correct_count"   => 0,
            "incorrect_count" => 0,
            "exercises" => a_collection_containing_exactly(
              { "content_json" => a_kind_of(String),
                "answered_count" => 0,
                "answers" => a_kind_of(Array) },
              { "content_json" => a_kind_of(String),
                "answered_count" => 0,
                "answers" => a_kind_of(Array) }
            )
          )
        },
        "periods" => []
      }
    )
    representation['stats']['course']['spaced_pages'].first['exercises'].each do |exercise|
      exercise['answers'].each do |answer|
        expect(answer['selected_count']).to eq 0
      end
    end
  end

end
