require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, :type => :representer do

  let(:task_plan) {
    FactoryGirl.create(:task_plan)
  }
  let(:statistics){
    CalculateTaskPlanStatistics.call(plan:task_plan).outputs[:statistics]
  }
  let(:representation) { Api::V1::TaskStatsRepresenter.new(statistics).as_json }

  it "represents a tasked exercise's stats" do
    expect(representation).to include(
      "course" => a_hash_including(
        "total_count"              => a_value_between(0,100),
        "complete_count"           => a_value_between(0,100),
        "partially_complete_count" => a_value_between(0,100),
        "current_pages"            => a_collection_including(
          a_hash_including(
            "correct_count"   => a_value_between(0,100),
            "incorrect_count" => a_value_between(0,100),
            "page" => a_hash_including(
              "id"     => be_a_kind_of(Fixnum),
              "number" => a_string_matching(/\d+.\d+/),
              "title"  => be_a_kind_of(String)
            )
          )
        ),
        "spaced_pages" => a_collection_including(
          a_hash_including(
            "correct_count"   => a_value_between(0,100),
            "incorrect_count" => a_value_between(0,100),
            "page" => a_hash_including(
              "id"     => be_a_kind_of(Fixnum),
              "number" => a_string_matching(/\d+.\d+/),
              "title"  => be_a_kind_of(String)
            ),
            "previous_attempt" => a_hash_including(
              "correct_count"   => a_value_between(0,100),
              "incorrect_count" => a_value_between(0,100),
              "page" => a_hash_including(
                "id"     => be_a_kind_of(Fixnum),
                "number" => a_string_matching(/\d+.\d+/),
                "title"  => be_a_kind_of(String)
              )
            )
          )
        )
      )
    )

  end


end
