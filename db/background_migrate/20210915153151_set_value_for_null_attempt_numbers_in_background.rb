class SetValueForNullAttemptNumbersInBackground < ActiveRecord::Migration[5.2]
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  def up
    tes_to_update = Tasks::Models::TaskedExercise.joins(:task_step).where(
      attempt_number: nil
    ).limit(BATCH_SIZE)

    loop do
      num_updated = tes_to_update.where.not(
        task_step: { first_completed_at: nil }
      ).update_all(attempt_number: 1)

      break if num_updated < BATCH_SIZE
    end

    loop do
      num_updated = tes_to_update.where(
        task_step: { first_completed_at: nil }
      ).update_all(attempt_number: 0)

      break if num_updated < BATCH_SIZE
    end

    change_column_null :tasks_tasked_exercises, :attempt_number, false
  end

  def down
  end
end
