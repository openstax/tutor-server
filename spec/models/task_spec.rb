require 'rails_helper'

RSpec.describe Task, :type => :model do
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to have_many(:task_steps).dependent(:destroy) }
  it { is_expected.to have_many(:taskings).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:task_plan) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:opens_at) }

  it "requires non-nil due_at to be after opens_at" do
    task = FactoryGirl.build(:task, due_at: nil)
    expect(task).to be_valid

    task = FactoryGirl.build(:task, due_at: Time.now - 1.week)
    expect(task).to_not be_valid
  end

  it "reports is_shared correctly" do
    at1 = FactoryGirl.create(:tasking)
    at1.reload
    expect(at1.task.is_shared).to be_falsy

    at2 = FactoryGirl.create(:tasking, task: at1.task)
    at1.reload
    expect(at1.task.is_shared).to be_truthy
  end

  it 'reports tasked_to? for a taskee' do
    user = FactoryGirl.create(:user)
    tasking = FactoryGirl.build(:tasking, taskee: user)
    task = FactoryGirl.create(:task, taskings: [tasking])

    expect(task).to be_tasked_to(user)

    task.taskings.clear
    expect(task).not_to be_tasked_to(user)
  end

  it 'returns the core task steps' do
    core_step1            = instance_double('TaskStep', :is_core? => true)
    core_step2            = instance_double('TaskStep', :is_core? => true)
    core_step3            = instance_double('TaskStep', :is_core? => true)
    spaced_practice_step1 = instance_double('TaskStep', :is_core? => false)
    spaced_practice_step2 = instance_double('TaskStep', :is_core? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    core_steps = task.core_task_steps

    expect(core_steps.size).to eq(3)
    expect(core_steps).to include(core_step1)
    expect(core_steps).to include(core_step2)
    expect(core_steps).to include(core_step3)
  end

  it 'can be started' do
    task = FactoryGirl.build(:task)
    start_time = Time.now
    expect(task.started?).to be_falsy
    task.start(start_time: start_time)
    expect(task.started?).to be_truthy
    expect(task.started_at).to eq(start_time)
  end

  it 'can determine if it is completed' do
    core_step1            = instance_double('TaskStep', :completed? => true)
    core_step2            = instance_double('TaskStep', :completed? => true)
    core_step3            = instance_double('TaskStep', :completed? => true)
    spaced_practice_step1 = instance_double('TaskStep', :completed? => true)
    spaced_practice_step2 = instance_double('TaskStep', :completed? => true)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.completed?).to be_truthy
  end

  it 'can determine if it is not completed' do
    core_step1            = instance_double('TaskStep', :completed? => true)
    core_step2            = instance_double('TaskStep', :completed? => true)
    core_step3            = instance_double('TaskStep', :completed? => false)
    spaced_practice_step1 = instance_double('TaskStep', :completed? => false)
    spaced_practice_step2 = instance_double('TaskStep', :completed? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.completed?).to be_falsy
  end

  it 'can determine when it was completed' do
    time1 = Time.now
    time2 = time1 + 1.minute
    time3 = time1 + 2.minutes
    time4 = time1 + 3.minutes
    time5 = time1 + 4.minutes
    core_step1            = instance_double('TaskStep', :completed? => true, :completed_at => time1)
    core_step2            = instance_double('TaskStep', :completed? => true, :completed_at => time2)
    core_step3            = instance_double('TaskStep', :completed? => true, :completed_at => time3)
    spaced_practice_step1 = instance_double('TaskStep', :completed? => true, :completed_at => time4)
    spaced_practice_step2 = instance_double('TaskStep', :completed? => true, :completed_at => time5)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.completed_at).to eq(time5)
  end

  it 'can determine if its core task steps are completed' do
    core_step1            = instance_double('TaskStep', :is_core? => true,  :completed? => true)
    core_step2            = instance_double('TaskStep', :is_core? => true,  :completed? => true)
    core_step3            = instance_double('TaskStep', :is_core? => true,  :completed? => true)
    spaced_practice_step1 = instance_double('TaskStep', :is_core? => false, :completed? => false)
    spaced_practice_step2 = instance_double('TaskStep', :is_core? => false, :completed? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.core_task_steps_completed?).to be_truthy
  end

  it 'can determine if its core task steps are not completed' do
    core_step1            = instance_double('TaskStep', :is_core? => true,  :completed? => true)
    core_step2            = instance_double('TaskStep', :is_core? => true,  :completed? => true)
    core_step3            = instance_double('TaskStep', :is_core? => true,  :completed? => false)
    spaced_practice_step1 = instance_double('TaskStep', :is_core? => false, :completed? => false)
    spaced_practice_step2 = instance_double('TaskStep', :is_core? => false, :completed? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.core_task_steps_completed?).to be_falsy
  end
end
