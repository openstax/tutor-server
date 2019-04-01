class RenameGarbageToResponse < ActiveRecord::Migration
  def change
    rename_column :tasks_tasked_exercises, :garbage_estimate, :response_validation
  end
end
