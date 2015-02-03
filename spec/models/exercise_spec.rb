require 'rails_helper'

RSpec.describe Exercise, :type => :model do
  it { is_expected.to have_one(:task_step).dependent(:destroy) }

  it "should delegate url and content to its task_step" do
    exercise = FactoryGirl.create(:exercise)
    expect(exercise.url).to eq exercise.task_step.url
    expect(exercise.content).to eq exercise.task_step.content
  end
end
