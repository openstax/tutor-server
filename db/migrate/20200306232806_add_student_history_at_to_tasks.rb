class AddStudentHistoryAtToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :student_history_at, :datetime

    reversible do |dir|
      dir.up do
        Tasks::Models::Task.where('"completed_core_steps_count" = "core_steps_count"').update_all(
          '"student_history_at" = "last_worked_at"'
        )
      end
    end
  end
end
