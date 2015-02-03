require 'rails_helper'

RSpec.describe InteractiveStep, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url, content, completed to its task_step" do
    interactive_step = FactoryGirl.create(:interactive_step)
    expect(interactive_step.url).to eq interactive_step.task_step.url
    expect(interactive_step.content).to eq interactive_step.task_step.content
    expect(interactive_step.completed_at).to(
      eq interactive_step.task_step.completed_at
    )
    expect(interactive_step.completed?).to eq interactive_step.task_step.completed?
    interactive_step.complete
    expect(interactive_step.completed_at).to(
      eq interactive_step.task_step.completed_at
    )
    expect(interactive_step.completed?).to eq interactive_step.task_step.completed?
  end
end
