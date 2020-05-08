class RenameStudentHistoryAtToCoreStepsCompletedAt < ActiveRecord::Migration[5.2]
  def change
    rename_column :tasks_tasks, :student_history_at, :core_steps_completed_at
  end
end
