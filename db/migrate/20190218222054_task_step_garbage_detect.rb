class TaskStepGarbageDetect < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasked_exercises, :garbage_estimate, :jsonb
  end
end
