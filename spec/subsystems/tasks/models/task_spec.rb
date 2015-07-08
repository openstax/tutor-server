require 'rails_helper'

RSpec.describe Tasks::Models::Task, :type => :model do
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to have_many(:task_steps).dependent(:destroy) }
  it { is_expected.to have_many(:taskings) }

  it { is_expected.to validate_presence_of(:title) }

  it "requires non-nil due_at to be after opens_at" do
    task = FactoryGirl.build(:tasks_task, due_at: nil)
    expect(task).to be_valid

    task = FactoryGirl.build(:tasks_task, due_at: Time.now - 1.week)
    expect(task).to_not be_valid
  end

  it "reports is_shared? correctly" do
    task1 = FactoryGirl.create(:tasks_task)
    FactoryGirl.create(:tasks_tasking, task: task1.entity_task)
    expect(task1.is_shared?).to be_falsy

    FactoryGirl.create(:tasks_tasking, task: task1.entity_task)
    expect(task1.is_shared?).to be_truthy
  end

  xit 'returns core task steps' do
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

  xit 'returns spaced_practice task steps' do
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

  xit 'returns personalized task steps' do
    core_step1         = instance_double('TaskStep', :personalized_group? => false)
    core_step2         = instance_double('TaskStep', :personalized_group? => false)
    core_step3         = instance_double('TaskStep', :personalized_group? => false)
    personalized_step1 = instance_double('TaskStep', :personalized_group? => true)
    personalized_step2 = instance_double('TaskStep', :personalized_group? => true)
    task_steps = [core_step1, core_step2, core_step3, personalized_step1, personalized_step2]
    task = Tasks::Models::Task.new
    allow(task).to receive(:task_steps).and_return(task_steps)

    personalized_steps = task.personalized_task_steps

    expect(personalized_steps.size).to eq(2)
    [personalized_step1, personalized_step2].each do |step|
      expect(personalized_steps).to include(step)
    end
  end

  xit 'determines if its core task steps are completed' do
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

  xit 'determines if its core task steps are not completed' do
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

  it 'can store and retrieve a personalized placeholder strategy object' do
    obj = OpenStruct.new(value: :correct)
    task = Tasks::Models::Task.new
    expect(task.personalized_placeholder_strategy).to be_nil
    task.personalized_placeholder_strategy = obj
    expect(task.personalized_placeholder_strategy).to eq(obj)
    expect(task.personalized_placeholder_strategy.value).to eq(:correct)
    expect(task.personalized_placeholder_strategy).to_not equal(obj)
    task.personalized_placeholder_strategy = nil
    expect(task.personalized_placeholder_strategy).to be_nil
  end

  it 'knows when feedback should be available' do
    task = FactoryGirl.build(:tasks_task, due_at: nil)
    task.feedback_at = nil
    expect(task.feedback_available?).to eq false

    task.feedback_at = Time.now
    expect(task.feedback_available?).to eq true

    task.feedback_at = Time.now + 1.minute
    expect(task.feedback_available?).to eq false
  end

  it 'can store and retrieve LOs' do
    task = Tasks::Models::Task.new
    expect(task.los).to be_empty
    task.los = ['a', 'b', 'c']
    expect(task.los).to eq(['a', 'b', 'c'])
    task.los << 'd'
    expect(task.los).to eq(['a', 'b', 'c', 'd'])
  end

  it 'counts exercise steps' do
    task = FactoryGirl.create(:tasks_task,
                              task_type: :homework,
                              step_types: [:tasks_tasked_exercise,
                                           :tasks_tasked_reading,
                                           :tasks_tasked_exercise,
                                           :tasks_tasked_exercise])

    Hacks::AnswerExercise[task_step: task.task_steps[0], is_correct: true]
    Hacks::AnswerExercise[task_step: task.task_steps[3], is_correct: false]

    task.reload

    expect(task.exercise_count).to eq 3
    expect(task.completed_exercise_count).to eq 2
    expect(task.correct_exercise_count).to eq 1
  end

end
