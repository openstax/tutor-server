# Not idempotent, cannot run in the background
# MIN/MAX are used to fix errors that might already have happened (but they are not perfect)
class FixAcceptedLateCounts < ActiveRecord::Migration[4.2]
  def up
    Tasks::Models::Task.select(:id).where.not(accepted_late_at: nil).find_in_batches do |tasks|
      Tasks::Models::Task.where(id: tasks.map(&:id)).update_all(
        <<-UPDATE_SQL.strip_heredoc
          "completed_accepted_late_steps_count" = LEAST(
            "completed_accepted_late_steps_count" +
            "completed_on_time_steps_count",
            "completed_steps_count"
          ),
          "completed_accepted_late_exercise_steps_count" = LEAST(
            "completed_accepted_late_exercise_steps_count" +
            "completed_on_time_exercise_steps_count",
            "completed_exercise_steps_count"
          ),
          "correct_accepted_late_exercise_steps_count" = LEAST(
            "correct_accepted_late_exercise_steps_count" +
            "correct_on_time_exercise_steps_count",
            "correct_exercise_steps_count"
          )
        UPDATE_SQL
      )
    end
  end

  def down
    Tasks::Models::Task.select(:id).where.not(accepted_late_at: nil).find_in_batches do |tasks|
      Tasks::Models::Task.where(id: tasks.map(&:id)).update_all(
        <<-UPDATE_SQL.strip_heredoc
          "completed_accepted_late_steps_count" = GREATEST(
            "completed_accepted_late_steps_count" -
            "completed_on_time_steps_count",
            0
          ),
          "completed_accepted_late_exercise_steps_count" = GREATEST(
            "completed_accepted_late_exercise_steps_count" -
            "completed_on_time_exercise_steps_count",
            0
          ),
          "correct_accepted_late_exercise_steps_count" = GREATEST(
            "correct_accepted_late_exercise_steps_count" -
            "correct_on_time_exercise_steps_count",
            0
          )
        UPDATE_SQL
      )
    end
  end
end
