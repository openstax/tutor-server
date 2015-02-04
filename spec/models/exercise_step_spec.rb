require 'rails_helper'

RSpec.describe ExerciseStep, :type => :model do
  it { is_expected.to belong_to(:task_step_exercise) }
  it { is_expected.to belong_to(:step) }

  it { is_expected.to validate_presence_of(:task_step_exercise) }
  it { is_expected.to validate_presence_of(:step) }

  it { is_expected.to validate_numericality_of(:number) }

  it "automatically sets the number" do
    exercise_step = ExerciseStep.new
    exercise_step.valid?
    expect(exercise_step.number).to_not be_nil
  end

  it "requires step to be unique" do
    exercise_step = FactoryGirl.create(:exercise_step)
    expect(exercise_step).to be_valid

    expect(FactoryGirl.build(:exercise_step,
                             step: exercise_step.step)).to_not be_valid
  end

  it "requires number to be unique for each task_step_exercise" do
    exercise_step = FactoryGirl.create(:exercise_step)
    expect(exercise_step).to be_valid

    expect(FactoryGirl.build(
             :exercise_step,
             task_step_exercise: exercise_step.task_step_exercise,
             number: exercise_step.number
          )).to_not be_valid
  end

  it "assigns an increasing number for each step" do
    task_step_exercise = FactoryGirl.build(:task_step_exercise)
    exercise_step_1 = FactoryGirl.build(:exercise_step,
                                        task_step_exercise: task_step_exercise)
    task_step_exercise.exercise_steps << exercise_step_1
    exercise_step_2 = FactoryGirl.build(:exercise_step,
                                        task_step_exercise: task_step_exercise)
    task_step_exercise.exercise_steps << exercise_step_2
    exercise_step_3 = FactoryGirl.build(:exercise_step,
                                        task_step_exercise: task_step_exercise)
    task_step_exercise.exercise_steps << exercise_step_3

    task_step_exercise.save!
    task_step_exercise.reload

    expect(exercise_step_1.number).to be < exercise_step_2.number
    expect(exercise_step_2.number).to be < exercise_step_3.number
  end
end
