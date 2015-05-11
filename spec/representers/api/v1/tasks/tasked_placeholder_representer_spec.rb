require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedPlaceholderRepresenter, :type => :representer do
  let!(:task_step) {
    @task_step = instance_double(Tasks::Models::TaskStep)
    allow(@task_step).to receive(:id).and_return(15)
    allow(@task_step).to receive(:tasks_task_id).and_return(42)
    allow(@task_step).to receive(:group_name).and_return('Some group')
    allow(@task_step).to receive(:completed?).and_return(false)
    allow(@task_step).to receive(:feedback_available?).and_return(false)
    allow(@task_step).to receive(:related_content).and_return([])
    @task_step
  }

  let!(:tasked_placeholder) {
    @tasked_placeholder = instance_double(Tasks::Models::TaskedPlaceholder)

    ## Avoid rspec double class when figuring out :type
    allow(@tasked_placeholder).to receive(:class).and_return(Tasks::Models::TaskedPlaceholder)

    allow(@tasked_placeholder).to receive(:task_step).and_return(@task_step)

    ## TaskedPlaceholder-specific properties
    allow(@tasked_placeholder).to receive(:placeholder_name).and_return('Some step type')

    @tasked_placeholder
  }

  let(:representation) { ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::Tasks::TaskedPlaceholderRepresenter.new(tasked_placeholder).as_json
  }

  it "'type' == 'placeholder'" do
    expect(representation).to include("type" => "placeholder")
  end

  it "has the correct 'placeholder_for'" do
    expect(representation).to include("placeholder_for" => 'Some step type')
  end

  it "correctly references the TaskStep and Task ids" do
    expect(representation).to include(
      "id"      => 15.to_s,
      "task_id" => 42.to_s
    )
  end

  it "'is_completed' == false" do
    expect(representation).to include("is_completed" => false)
  end

  it "has the correct 'group'" do
    expect(representation).to include("group" => 'Some group')
  end

  it "has 'related_content'" do
    expect(representation).to include("related_content")
  end

end
