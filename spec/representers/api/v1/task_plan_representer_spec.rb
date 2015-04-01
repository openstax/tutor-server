require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, :type => :representer do

  let(:task_plan) {
    FactoryGirl.create(:tasks_task_plan)
  }
  let(:representation) { Api::V1::TaskPlanRepresenter.new(task_plan).as_json }

  it "represents a task plan" do
    expect(representation).to include(
      "id" => task_plan.id,
      "type" => task_plan.type,
    )
    expect(representation["stats"]).to be_nil
  end


end
