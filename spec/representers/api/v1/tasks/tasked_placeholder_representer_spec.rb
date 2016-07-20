require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedPlaceholderRepresenter, type: :representer do
  let(:task_step) {
    step = instance_double(Tasks::Models::TaskStep)
    allow(step).to receive(:id).and_return(15)
    allow(step).to receive(:tasks_task_id).and_return(42)
    allow(step).to receive(:group_name).and_return('Some group')
    allow(step).to receive(:completed?).and_return(false)
    allow(step).to receive(:feedback_available?).and_return(false)
    allow(step).to receive(:can_be_recovered?).and_return(false)
    allow(step).to receive(:related_content).and_return([])
    allow(step).to receive(:labels).and_return([])
    step
  }

  let(:tasked_placeholder) {
    placeholder = instance_double(Tasks::Models::TaskedPlaceholder)

    ## Avoid rspec double class when figuring out :type
    allow(placeholder).to receive(:class).and_return(Tasks::Models::TaskedPlaceholder)

    allow(placeholder).to receive(:task_step).and_return(task_step)
    allow(placeholder).to receive(:can_be_recovered?).and_return(false)

    ## TaskedPlaceholder-specific properties
    allow(placeholder).to receive(:placeholder_name).and_return('Some step type')
    allow(placeholder).to receive(:last_completed_at).and_return(Time.current)
    allow(placeholder).to receive(:first_completed_at).and_return(Time.current - 1.week)

    placeholder
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

  it "'has_recovery' == false" do
    expect(representation).to include("has_recovery" => false)
  end

  it "has the correct 'group'" do
    expect(representation).to include("group" => 'Some group')
  end

  it "has 'related_content'" do
    expect(representation).to include("related_content")
  end

end
