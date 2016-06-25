class ConvertHstoreFieldsToSerializedJson < ActiveRecord::Migration
  def up
    rename_column :tasks_tasks, :spy, :spy_old
    add_column :tasks_tasks, :spy, :text, null: false, default: '{}'

    Tasks::Models::Task.find_each{ |task| task.update_attribute :spy, task.spy_old }

    remove_column :tasks_tasks, :spy_old
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
