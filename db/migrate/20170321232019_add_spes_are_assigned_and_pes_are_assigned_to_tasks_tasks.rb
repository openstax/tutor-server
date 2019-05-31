class AddSpesAreAssignedAndPesAreAssignedToTasksTasks < ActiveRecord::Migration[4.2]
  def up
    add_column :tasks_tasks, :spes_are_assigned, :boolean, null: false, default: false
    add_column :tasks_tasks, :pes_are_assigned,  :boolean, null: false, default: false
  end

  def down
    remove_column :tasks_tasks, :spes_are_assigned
    remove_column :tasks_tasks, :pes_are_assigned
  end
end
