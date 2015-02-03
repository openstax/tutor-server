require 'rails_helper'

RSpec.describe Interactive, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url and content to its task_step" do
    interactive = FactoryGirl.create(:interactive)
    expect(interactive.url).to eq interactive.task_step.url
    expect(interactive.content).to eq interactive.task_step.content
  end
end
