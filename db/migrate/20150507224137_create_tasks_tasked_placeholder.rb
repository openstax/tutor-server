class CreateTasksTaskedPlaceholder < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_tasked_placeholders do |t|
      t.integer :placeholder_type, default: 0, null: false
    end
  end
end
