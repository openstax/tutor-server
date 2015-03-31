require 'rails_helper'

RSpec.describe RecoverTaskedExercise, :type => :routine do

  let!(:tasked_reading)  { FactoryGirl.create(:tasks_tasked_reading) }
  let!(:tasked_exercise) { FactoryGirl.create(:tasks_tasked_exercise) }
  let!(:tasked_exercise_with_recovery) {
    FactoryGirl.create(:tasks_tasked_exercise, has_recovery: true)
  }

  it "cannot be called on taskeds without a recovery step" do
    result = nil
    expect {
      result = RecoverTaskedExercise.call(tasked_exercise: tasked_reading)
    }.not_to change{ tasked_reading.task_step }
    expect(result.errors.first.code).to eq(:recovery_not_available)

    result = nil
    expect {
      result = RecoverTaskedExercise.call(tasked_exercise: tasked_exercise)
    }.not_to change{ tasked_reading.task_step }
    expect(result.errors.first.code).to eq(:recovery_not_available)
  end

  it "adds an extra recovery step after the given step" do
    result = nil
    recovery_step = nil
    next_step = tasked_exercise.task_step.next_by_number
    expect {
      result = RecoverTaskedExercise.call(
        tasked_exercise: tasked_exercise_with_recovery
      )
    }.to change{ tasked_exercise }

    expect(result.errors).to be_empty
    expect(recovery_step.tasked).to be_a(TaskedExercise)
    expect(recovery_step.number).to(
      eq tasked_exercise_with_recovery.task_step.number + 1
    )
    expect(next_step.number).to eq recovery_step.number + 1
  end

end
