require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, :type => :representer do

  let(:task_plan) {
    FactoryGirl.create(:tasks_task_plan)
  }
  let(:representation) { Api::V1::TaskPlanRepresenter.new(task_plan).as_json }

  it "represents a task plan" do
    expect(representation).to include(
      "id" => task_plan.id.to_s,
      "type" => task_plan.type
    )
    expect(representation["stats"]).to be_nil
  end

  it "includes published_at when published" do
      task_plan.update_attributes(published_at: Time.now)
      representation = Api::V1::TaskPlanRepresenter.new(task_plan).as_json
      expect(representation).to include(
        "published_at" => DateTimeUtilities.to_api_s(task_plan.published_at)
      )
  end

end
