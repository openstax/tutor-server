class IndexTasksAndTaskingPlansOnOpensAtNtz < ActiveRecord::Migration
  def change
    add_index :tasks_tasks, :opens_at_ntz
    add_index :tasks_tasking_plans, :opens_at_ntz
  end
end
