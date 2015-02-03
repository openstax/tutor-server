require 'rails_helper'

RSpec.describe InteractiveStep, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url and content to its task_step" do
    interactive_step = FactoryGirl.create(:interactive_step)
    expect(interactive_step.url).to eq interactive_step.task_step.url
    expect(interactive_step.content).to eq interactive_step.task_step.content
  end
end
