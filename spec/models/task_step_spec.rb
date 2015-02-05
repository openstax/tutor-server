require 'rails_helper'

RSpec.describe TaskStep, :type => :model do
  subject(:task_step) { FactoryGirl.create :task_step }

  it { is_expected.to belong_to(:task) }
  it { is_expected.to belong_to(:step) }

  it { is_expected.to validate_presence_of(:task) }
  it { is_expected.to validate_presence_of(:step) }

  it { is_expected.to validate_numericality_of(:number) }

  it "requires step to be unique" do
    expect(task_step).to be_valid

    expect(FactoryGirl.build(:task_step,
                             step: task_step.step)).not_to be_valid
  end

  # TODO: Move specs below to sortability gem (with dummy models)
  it "automatically sets the number" do
    task_step = FactoryGirl.build :task_step
    expect(task_step).to be_valid
    expect(task_step.number).not_to be_nil
  end

  it "requires number to be unique for each task" do
    task_step = FactoryGirl.create(:task_step)
    expect(task_step).to be_persisted

    expect(FactoryGirl.build(:task_step,
                             task: task_step.task,
                             number: task_step.number)).not_to be_valid
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
end
