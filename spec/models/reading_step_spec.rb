require 'rails_helper'

RSpec.describe ReadingStep, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url, content, completed to its task_step" do
    reading_step = FactoryGirl.create(:reading_step)
    expect(reading_step.url).to eq reading_step.task_step.url
    expect(reading_step.content).to eq reading_step.task_step.content
    expect(reading_step.completed_at).to(
      eq reading_step.task_step.completed_at
    )
    expect(reading_step.completed?).to eq reading_step.task_step.completed?
    reading_step.complete
    expect(reading_step.completed_at).to(
      eq reading_step.task_step.completed_at
    )
    expect(reading_step.completed?).to eq reading_step.task_step.completed?
  end
end
