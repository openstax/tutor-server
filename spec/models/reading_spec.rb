require 'rails_helper'

RSpec.describe Reading, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url and content to its task_step" do
    reading = FactoryGirl.create(:reading)
    expect(reading.url).to eq reading.task_step.url
    expect(reading.content).to eq reading.task_step.content
  end
end
