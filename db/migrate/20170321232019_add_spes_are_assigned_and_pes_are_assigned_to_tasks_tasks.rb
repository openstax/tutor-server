class AddSpesAreAssignedAndPesAreAssignedToTasksTasks < ActiveRecord::Migration
  def up
    add_column :tasks_tasks, :spes_are_assigned, :boolean, null: false, default: false
    add_column :tasks_tasks, :pes_are_assigned,  :boolean, null: false, default: false

    Tasks::Models::Task.update_all(spes_are_assigned: true, pes_are_assigned: true)
    Tasks::Models::Task.joins(:task_steps).where(task_steps: {
      group_type: Tasks::Models::TaskStep.group_types[:spaced_practice_group],
      tasked_type: 'Tasks::Models::TaskedPlaceholder'
    }).update_all(spes_are_assigned: false)
    Tasks::Models::Task.joins(:task_steps).where(task_steps: {
      group_type: Tasks::Models::TaskStep.group_types[:personalized_group],
      tasked_type: 'Tasks::Models::TaskedPlaceholder'
    }).update_all(pes_are_assigned: false)
  end

  def down
    remove_column :tasks_tasks, :spes_are_assigned
    remove_column :tasks_tasks, :pes_are_assigned
  end
end
