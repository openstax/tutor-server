require 'rails_helper'

RSpec.describe ReadingStep, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url and content to its task_step" do
    reading_step = FactoryGirl.create(:reading_step)
    expect(reading_step.url).to eq reading_step.task_step.url
    expect(reading_step.content).to eq reading_step.task_step.content
  end
end
