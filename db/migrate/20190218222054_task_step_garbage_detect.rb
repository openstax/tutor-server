class TaskStepGarbageDetect < ActiveRecord::Migration
  def change
    add_column :tasks_tasked_exercises, :garbage_estimate, :jsonb
  end
end
