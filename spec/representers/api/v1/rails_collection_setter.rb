require 'rails_helper'

RSpec.describe Api::V1::RailsCollectionSetter, type: :representer do
  let(:represented) { Tasks::Models::TaskPlan.new }
  let(:input)       { 3.times.map{ Tasks::Models::TaskingPlan.new } }
  let(:binding)     { OpenStruct.new getter: 'tasking_plans' }

  it 'assigns the input to the collection without throwing errors for invalid records' do
    expect do
      described_class.call(input: input, represented: represented, binding: binding)
    end.not_to raise_error

    expect(represented.tasking_plans).to eq input

    expect(represented).not_to be_valid
    represented.tasking_plans.each do |tasking_plan|
      expect(tasking_plan).not_to be_valid
    end
  end
end
