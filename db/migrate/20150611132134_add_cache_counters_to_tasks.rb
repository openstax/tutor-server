class AddCacheCountersToTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :exercise_count, :integer, null: false, default: 0
    add_index :tasks_tasks, :exercise_count
    add_column :tasks_tasks, :correct_exercise_count, :integer, null: false, default: 0
    add_index :tasks_tasks, :correct_exercise_count
    add_column :tasks_tasks, :recovered_exercise_count, :integer, null: false, default: 0
    add_index :tasks_tasks, :recovered_exercise_count
  end
end
