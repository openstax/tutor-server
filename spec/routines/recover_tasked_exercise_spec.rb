require 'rails_helper'

RSpec.describe RecoverTaskedExercise, :type => :routine do

  let!(:tasked_reading)  { FactoryGirl.create(:tasked_reading) }
  let!(:tasked_exercise) { FactoryGirl.create(:tasked_exercise) }
  let!(:recovery)        { FactoryGirl.create(:tasked_exercise,
                                              task_step: nil) }
  let!(:tasked_exercise_with_recovery) {
    FactoryGirl.create(:tasked_exercise, recovery_tasked_exercise: recovery)
  }

  it "cannot be called on taskeds without a recovery step" do
    result = nil
    expect {
      result = RecoverTaskedExercise.call(tasked_exercise: tasked_reading)
    }.not_to change{ tasked_reading.task_step }
    expect(result.errors.first.code).to eq(:missing_recovery_exercise)

    result = nil
    expect {
      result = RecoverTaskedExercise.call(tasked_exercise: tasked_exercise)
    }.not_to change{ tasked_reading.task_step }
    expect(result.errors.first.code).to eq(:missing_recovery_exercise)
  end

  # FIXME either this spec or the RecoverTaskedExercise itself is broken
  # It attempts to add a a duplicate TaskStep, which runs into
  # unique validation on TaskStep#tasked_id
  xit "adds an extra recovery step after the given step" do
    recovery = tasked_exercise_with_recovery.recovery_tasked_exercise
    result = nil
    expect {
      result = RecoverTaskedExercise.call(
        tasked_exercise: tasked_exercise_with_recovery
      )
    }.to change{ tasked_reading.task_step.tasked }

    expect(result.errors).to be_empty
    expect(recovery.task_step.task).to(
      eq tasked_exercise_with_recovery.task_step.task
    )
    expect(recovery.task_step.number).to(
      eq tasked_exercise_with_recovery.task_step.number + 1
    )
  end

end
