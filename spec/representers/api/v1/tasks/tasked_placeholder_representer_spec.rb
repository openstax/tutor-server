require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedPlaceholderRepresenter, type: :representer do
  let(:task_step) do
    instance_double(Tasks::Models::TaskStep).tap do |step|
      allow(step).to receive(:id).and_return(15)
      allow(step).to receive(:tasks_task_id).and_return(42)
      allow(step).to receive(:group_name).and_return('Some group')
      allow(step).to receive(:is_core).and_return(false)
      allow(step).to receive(:completed?).and_return(false)
      allow(step).to receive(:can_be_updated?).and_return(true)

      allow(step).to receive(:spy_with_response_validation).and_return({})
    end
  end

  let(:tasked_placeholder) do
    instance_double(Tasks::Models::TaskedPlaceholder).tap do |placeholder|
      ## Avoid rspec double class when figuring out :type
      allow(placeholder).to receive(:class).and_return(Tasks::Models::TaskedPlaceholder)
      allow(placeholder).to receive(:task_step).and_return(task_step)
      allow(placeholder).to receive(:can_be_recovered?).and_return(false)

      ## TaskedPlaceholder-specific properties
      allow(placeholder).to receive(:placeholder_type).and_return('some_exercise_type')
      allow(placeholder).to receive(:last_completed_at).and_return(Time.current)
      allow(placeholder).to receive(:first_completed_at).and_return(Time.current - 1.week)
      allow(placeholder).to receive(:available_points).and_return(1.0)
      allow(placeholder).to receive(:cache_key).and_return('tasks/models/tasked_placeholders/42')
      allow(placeholder).to receive(:cache_version).and_return('test')
    end
  end

  let(:representation) do ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::Tasks::TaskedPlaceholderRepresenter.new(tasked_placeholder).as_json
  end

  let(:complete_representation) do ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::Tasks::TaskedPlaceholderRepresenter.new(tasked_placeholder).to_hash(
      user_options: { include_content: true }
    )
  end

  it "'type' == 'placeholder'" do
    expect(representation).to include('type' => 'placeholder')
  end

  it "has the correct 'placeholder_for'" do
    expect(representation).to include('placeholder_for' => 'some_exercise_type')
  end

  it 'correctly references the TaskStep and Task ids' do
    expect(representation).to include('id' => 15)
  end

  it "'is_completed' == false" do
    expect(representation).to include('is_completed' => false)
  end

  it 'has the correct available_points' do
    expect(representation).to include('available_points' => 1.0)
  end

  it "has the correct 'group'" do
    expect(representation).to include('group' => 'Some group')
  end

  it "has the correct 'is_core'" do
    expect(representation).to include('is_core' => false)
  end

  it "has 'spy'" do
    expect(complete_representation).to include('spy' => {})
  end
end
