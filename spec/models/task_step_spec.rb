require 'rails_helper'

RSpec.describe TaskStep, :type => :model do
  it { is_expected.to belong_to(:details) }
  it { is_expected.to belong_to(:task) }

  it { is_expected.to validate_presence_of(:details) }
  it { is_expected.to validate_presence_of(:task) }

  it { is_expected.to validate_numericality_of(:number) }

  it "automatically sets the number" do
    task_step = TaskStep.new
    task_step.valid?
    expect(task_step.number).to_not be_nil
  end

  it "requires details to be unique" do
    task_step = FactoryGirl.create(:task_step)
    expect(task_step).to be_valid

    expect(FactoryGirl.build(:task_step,
                             details: task_step.details)).to_not be_valid
  end

  it "requires number to be unique for each task" do
    task_step = FactoryGirl.create(:task_step)
    expect(task_step).to be_valid

    expect(FactoryGirl.build(:task_step,
                             task: task_step.task,
                             number: task_step.number)).to_not be_valid
  end

  it "assigns an increasing number for each step" do
    task_step = FactoryGirl.create(:task_step)
    expect(task_step).to be_valid

    task_step_2 = FactoryGirl.build(:task_step, task: task_step.task)
    expect(task_step_2).to be_valid
    expect(task_step_2.number).to be > task_step.number
  end
end
