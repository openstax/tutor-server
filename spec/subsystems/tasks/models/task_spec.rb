require 'rails_helper'

RSpec.describe Tasks::Models::Task, :type => :model do
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to have_many(:task_steps).dependent(:destroy) }
  it { is_expected.to have_many(:taskings).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:opens_at) }

  it "requires non-nil due_at to be after opens_at" do
    task = FactoryGirl.build(:tasks_task, due_at: nil)
    expect(task).to be_valid

    task = FactoryGirl.build(:tasks_task, due_at: Time.now - 1.week)
    expect(task).to_not be_valid
  end

  it "reports is_shared correctly" do
    task1 = FactoryGirl.create(:tasks_task)
    FactoryGirl.create(:tasks_tasking, task: task1.entity_task)
    expect(task1.is_shared).to be_falsy

    FactoryGirl.create(:tasks_tasking, task: task1.entity_task)
    expect(task1.is_shared).to be_truthy
  end

  it 'returns core task steps' do
    core_step1            = instance_double('TaskStep', :core_group? => true)
    core_step2            = instance_double('TaskStep', :core_group? => true)
    core_step3            = instance_double('TaskStep', :core_group? => true)
    spaced_practice_step1 = instance_double('TaskStep', :core_group? => false)
    spaced_practice_step2 = instance_double('TaskStep', :core_group? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Tasks::Models::Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    core_steps = task.core_task_steps

    expect(core_steps.size).to eq(3)
    [core_step1, core_step2, core_step3].each do |step|
      expect(core_steps).to include(step)
    end
  end

  it 'returns spaced_practice task steps' do
    core_step1            = instance_double('TaskStep', :spaced_practice_group? => false)
    core_step2            = instance_double('TaskStep', :spaced_practice_group? => false)
    core_step3            = instance_double('TaskStep', :spaced_practice_group? => false)
    spaced_practice_step1 = instance_double('TaskStep', :spaced_practice_group? => true)
    spaced_practice_step2 = instance_double('TaskStep', :spaced_practice_group? => true)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Tasks::Models::Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    spaced_practice_steps = task.spaced_practice_task_steps

    expect(spaced_practice_steps.size).to eq(2)
    [spaced_practice_step1, spaced_practice_step2].each do |step|
      expect(spaced_practice_steps).to include(step)
    end
  end

  it 'determines if its core task steps are completed' do
    core_step1            = instance_double('TaskStep', :core_group? => true,  :completed? => true)
    core_step2            = instance_double('TaskStep', :core_group? => true,  :completed? => true)
    core_step3            = instance_double('TaskStep', :core_group? => true,  :completed? => true)
    spaced_practice_step1 = instance_double('TaskStep', :core_group? => false, :completed? => false)
    spaced_practice_step2 = instance_double('TaskStep', :core_group? => false, :completed? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Tasks::Models::Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.core_task_steps_completed?).to be_truthy
  end

  it 'determines if its core task steps are not completed' do
    core_step1            = instance_double('TaskStep', :core_group? => true,  :completed? => true)
    core_step2            = instance_double('TaskStep', :core_group? => true,  :completed? => true)
    core_step3            = instance_double('TaskStep', :core_group? => true,  :completed? => false)
    spaced_practice_step1 = instance_double('TaskStep', :core_group? => false, :completed? => false)
    spaced_practice_step2 = instance_double('TaskStep', :core_group? => false, :completed? => false)
    task_steps = [core_step1, core_step2, core_step3, spaced_practice_step1, spaced_practice_step2]
    task = Tasks::Models::Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    expect(task.core_task_steps_completed?).to be_falsy
  end

  it 'handles TaskStep completion' do
    spa = instance_double('SpacedPracticeAlgorithmDefault')
    expect(spa).to receive(:call)
    task = Tasks::Models::Task.new
    expect(task).to receive(:spaced_practice_algorithm).and_return(spa)

    task.handle_task_step_completion!
  end

  it 'has a default Spaced Practice Algorithm' do
    spa = nil
    expect{
      spa = Tasks::Models::Task.new.spaced_practice_algorithm
    }.to_not raise_error
    expect(spa).to_not be_nil
    expect(spa).to respond_to(:call)
  end

  it 'replaces spaced practice TaskedPlaceholders upon completion of core TaskSteps' do
    task = Tasks::Models::Task.create(
      task_type: 'reading',
      title:     'Some Title',
      opens_at:  Time.now,
      due_at:    Time.now + 1.week
    )

    task_step1 = Tasks::Models::TaskStep.new(task: task, page_id: 3)
    task_step1.tasked = Tasks::Models::TaskedPlaceholder.new
    task_step1.core_group!
    task.task_steps << task_step1

    task_step2 = Tasks::Models::TaskStep.new(task: task, page_id: 3)
    task_step2.tasked = Tasks::Models::TaskedPlaceholder.new
    task_step2.core_group!
    task.task_steps << task_step2

    task_step3 = Tasks::Models::TaskStep.new(task: task, page_id: 3)
    task_step3.tasked = Tasks::Models::TaskedPlaceholder.new
    task_step3.spaced_practice_group!
    task.task_steps << task_step3

    task_step4 = Tasks::Models::TaskStep.new(task: task, page_id: 3)
    task_step4.tasked = Tasks::Models::TaskedPlaceholder.new
    task_step4.spaced_practice_group!
    task.task_steps << task_step4

    task.save!

    expect(Tasks::Models::TaskStep.count).to eq(4)
    expect(Tasks::Models::TaskedPlaceholder.count).to eq(4)
    expect(task.core_task_steps.count).to eq(2)
    expect(task.core_task_steps_completed?).to be_falsy
    expect(task.spaced_practice_task_steps.count).to eq(2)
    expect(task.spaced_practice_task_steps.collect{|ts| ts.tasked_type.demodulize}).to eq(['TaskedPlaceholder', 'TaskedPlaceholder'])

    MarkTaskStepCompleted.call(task_step: task_step1)

    expect(Tasks::Models::TaskStep.count).to eq(4)
    expect(Tasks::Models::TaskedPlaceholder.count).to eq(4)
    expect(task.core_task_steps.count).to eq(2)
    expect(task.core_task_steps_completed?).to be_falsy
    expect(task.spaced_practice_task_steps.count).to eq(2)
    expect(task.spaced_practice_task_steps.collect{|ts| ts.tasked_type.demodulize}).to eq(['TaskedPlaceholder', 'TaskedPlaceholder'])

    MarkTaskStepCompleted.call(task_step: task_step2)

    expect(Tasks::Models::TaskStep.count).to eq(4)
    expect(Tasks::Models::TaskedPlaceholder.count).to eq(2)
    expect(task.core_task_steps.count).to eq(2)
    expect(task.core_task_steps_completed?).to be_truthy
    expect(task.spaced_practice_task_steps.count).to eq(2)
    expect(task.spaced_practice_task_steps.collect{|ts| ts.tasked_type.demodulize}).to eq(['TaskedExercise', 'TaskedExercise'])

  end

end
