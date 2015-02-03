require 'rails_helper'

RSpec.describe TaskStep, :type => :model do
  it { is_expected.to belong_to(:details) }
  it { is_expected.to belong_to(:resource).dependent(:destroy) }
  it { is_expected.to belong_to(:task) }

  it { is_expected.to validate_presence_of(:details) }
  it { is_expected.to validate_presence_of(:resource) }
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
    task = FactoryGirl.build(:task)
    task_step_1 = FactoryGirl.build(:task_step, task: task)
    task.task_steps << task_step_1
    task_step_2 = FactoryGirl.build(:task_step, task: task)
    task.task_steps << task_step_2
    task_step_3 = FactoryGirl.build(:task_step, task: task)
    task.task_steps << task_step_3

    task.save!
    task.reload

    expect(task_step_1.number).to be < task_step_2.number
    expect(task_step_2.number).to be < task_step_3.number
  end

  it "should delegate url and content to its resource" do
    task_step = FactoryGirl.create(:task_step)
    expect(task_step.url).to eq task_step.resource.url
    expect(task_step.content).to eq task_step.resource.content
  end
end
