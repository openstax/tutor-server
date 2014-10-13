class ModifyFieldsInTask < ActiveRecord::Migration
  def change
    add_column :tasks, :title, :string
    change_column :tasks, :title, :string, null: false
    add_column :tasks, :assigned_tasks_count, :integer, default: 0
    change_column :tasks, :assigned_tasks_count, :integer, null: false

    remove_index :tasks, [:taskable_id, :taskable_type]
    remove_index :tasks, :user_id

    remove_column :tasks, :user_id
    remove_column :tasks, :taskable_type
    remove_column :tasks, :taskable_id
  end
end
