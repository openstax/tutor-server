require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlanWithStatsRepresenter, type: :representer,
                                                      speed: :medium,
                                                      vcr: VCR_OPTS do

  let!(:number_of_students){ 2 }

  let!(:task_plan) {
    allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [ [0, 2] ] }
    FactoryGirl.create :tasked_task_plan, number_of_students: number_of_students
  }

  let!(:representation) { Api::V1::TaskPlanWithStatsRepresenter.new(task_plan).as_json }

  it "represents a task plan's stats" do
    expect(representation).to include(
      "id" => task_plan.id.to_s,
      "type" => "reading",
      "stats" => {
        "course" => a_hash_including(
          "total_count"              => 2,
          "complete_count"           => 0,
          "partially_complete_count" => 0,
          "current_pages"            => a_collection_containing_exactly(
            a_hash_including(
              "id"     => task_plan.settings['page_ids'].first.to_s,
              "title"  => "Force",
              "student_count"   => 0,
              "correct_count"   => 0,
              "incorrect_count" => 0,
              "chapter_section" => [1, 1]
            )
          ),
          "spaced_pages" => a_collection_containing_exactly(
            a_hash_including(
              "id"     => task_plan.settings['page_ids'].first.to_s,
              "title"  => "Force",
              "student_count"   => 0,
              "correct_count"   => 0,
              "incorrect_count" => 0,
              "chapter_section" => [1, 1]
            )
          )
        ),
        "periods" => []
      }
    )
  end

end
