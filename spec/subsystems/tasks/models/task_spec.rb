require 'rails_helper'

RSpec.describe Tasks::Models::Task, type: :model do
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to have_many(:task_steps).dependent(:destroy) }
  it { is_expected.to have_many(:taskings) }

  it { is_expected.to validate_presence_of(:title) }

  it { is_expected.to validate_presence_of(:opens_at) }

  it 'is late when last_worked_at is past due_at' do
    task = FactoryGirl.create(:tasks_task, opens_at: Time.current - 1.week,
                                           due_at: Time.current - 1.day)

    expect(task).not_to be_late

    task.set_last_worked_at(time: Time.current)
    task.save

    expect(task).to be_late
  end

  describe '#handle_task_step_completion!' do
    it 'marks #last_worked_at to the completion_time' do
      time = Time.current
      task = FactoryGirl.create(:tasks_task)

      task.handle_task_step_completion!(completion_time: time)

      expect(task.last_worked_at).to eq(time)
    end
  end

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

  context "update step counts" do
    let!(:task) {
      tt = Tasks::Models::Task.new
      allow(tt).to receive(:save!)
      tt
    }

    let!(:step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(false)
        allow(step).to receive(:exercise?).and_return(false)
        allow(step).to receive(:placeholder?).and_return(false)
      end
    }

    let!(:completed_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(true)
        allow(step).to receive(:exercise?).and_return(false)
        allow(step).to receive(:placeholder?).and_return(false)
      end
    }

    let!(:core_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(true)
        allow(step).to receive(:completed?).and_return(false)
        allow(step).to receive(:exercise?).and_return(false)
        allow(step).to receive(:placeholder?).and_return(false)
      end
    }

    let!(:completed_core_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(true)
        allow(step).to receive(:completed?).and_return(true)
        allow(step).to receive(:exercise?).and_return(false)
        allow(step).to receive(:placeholder?).and_return(false)
      end
    }

    let!(:exercise_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(false)
        allow(step).to receive(:exercise?).and_return(true)
        allow(step).to receive(:placeholder?).and_return(false)
        allow(step).to receive(:tasked).and_return(
          instance_double(Tasks::Models::TaskedExercise).tap do |exercise|
            allow(exercise).to receive(:is_correct?).and_return(false)
          end
        )
      end
    }

    let!(:completed_exercise_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(true)
        allow(step).to receive(:exercise?).and_return(true)
        allow(step).to receive(:placeholder?).and_return(false)
        allow(step).to receive(:tasked).and_return(
          instance_double(Tasks::Models::TaskedExercise).tap do |exercise|
            allow(exercise).to receive(:is_correct?).and_return(false)
          end
        )
      end
    }

    let!(:correct_exercise_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(true)
        allow(step).to receive(:exercise?).and_return(true)
        allow(step).to receive(:placeholder?).and_return(false)
        allow(step).to receive(:tasked).and_return(
          instance_double(Tasks::Models::TaskedExercise).tap do |exercise|
            allow(exercise).to receive(:is_correct?).and_return(true)
          end
        )
      end
    }

    let!(:placeholder_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(false)
        allow(step).to receive(:exercise?).and_return(false)
        allow(step).to receive(:placeholder?).and_return(true)
        allow(step).to receive(:tasked).and_return(
          instance_double(Tasks::Models::TaskedPlaceholder).tap do |exercise|
            allow(exercise).to receive(:exercise_type?).and_return(false)
          end
        )
      end
    }

    let!(:placeholder_exercise_step) {
      instance_double(Tasks::Models::TaskStep).tap do |step|
        allow(step).to receive(:core_group?).and_return(false)
        allow(step).to receive(:completed?).and_return(false)
        allow(step).to receive(:exercise?).and_return(false)
        allow(step).to receive(:placeholder?).and_return(true)
        allow(step).to receive(:tasked).and_return(
          instance_double(Tasks::Models::TaskedPlaceholder).tap do |exercise|
            allow(exercise).to receive(:exercise_type?).and_return(true)
          end
        )
      end
    }

    context "steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.steps_count).to eq(0)
      end

      it "works with multiple steps" do
        allow(task).to receive(:task_steps).and_return([step, step])
        task.update_step_counts!
        expect(task.steps_count).to eq(2)
      end
    end

    context "completed steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.completed_steps_count).to eq(0)
      end

      it "works with multiple completed steps" do
        allow(task).to receive(:task_steps).and_return([completed_step, step, completed_step])
        task.update_step_counts!
        expect(task.completed_steps_count).to eq(2)
      end
    end

    context "core steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.core_steps_count).to eq(0)
      end

      it "works with multiple core steps" do
        allow(task).to receive(:task_steps).and_return([core_step, step, core_step])
        task.update_step_counts!
        expect(task.core_steps_count).to eq(2)
      end
    end

    context "completed core steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.completed_core_steps_count).to eq(0)
      end

      it "works with multiple completed core steps" do
        allow(task).to receive(:task_steps).and_return([completed_core_step, step, core_step, completed_core_step])
        task.update_step_counts!
        expect(task.completed_core_steps_count).to eq(2)
      end
    end

    context "exercise steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.exercise_steps_count).to eq(0)
      end

      it "works with multiple exercise steps" do
        allow(task).to receive(:task_steps).and_return([exercise_step, step, exercise_step])
        task.update_step_counts!
        expect(task.exercise_steps_count).to eq(2)
      end
    end

    context "completed exercise steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.completed_exercise_steps_count).to eq(0)
      end

      it "works with multiple completed exercise steps" do
        allow(task).to receive(:task_steps).and_return([completed_exercise_step, exercise_step, step, completed_exercise_step])
        task.update_step_counts!
        expect(task.completed_exercise_steps_count).to eq(2)
      end
    end

    context "correct exercise steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.correct_exercise_steps_count).to eq(0)
      end

      it "works with multiple correct exercise steps" do
        allow(task).to receive(:task_steps).and_return([correct_exercise_step, completed_exercise_step, correct_exercise_step])
        task.update_step_counts!
        expect(task.correct_exercise_steps_count).to eq(2)
      end
    end

    context "placeholder steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.placeholder_steps_count).to eq(0)
      end

      it "works with multiple placeholder steps" do
        allow(task).to receive(:task_steps).and_return([placeholder_step, step, placeholder_step])
        task.update_step_counts!
        expect(task.placeholder_steps_count).to eq(2)
      end
    end

    context "placeholder exercise steps count" do
      it "works with no steps" do
        allow(task).to receive(:task_steps).and_return([])
        task.update_step_counts!
        expect(task.placeholder_exercise_steps_count).to eq(0)
      end

      it "works with multiple placeholder exercise steps" do
        allow(task).to receive(:task_steps).and_return([placeholder_exercise_step, placeholder_step, placeholder_exercise_step])
        task.update_step_counts!
        expect(task.placeholder_exercise_steps_count).to eq(2)
      end
    end

  end
end
