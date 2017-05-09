class RemoveTaskedExerciseContent < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_column :tasks_tasked_exercises, :content, :text

    # Reclaim disk space that has been freed by dropping the very large content column
    execute 'VACUUM FULL ANALYZE tasks_tasked_exercises;'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
