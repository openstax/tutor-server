class CreateTasksTaskedPlaceholder < ActiveRecord::Migration
  def change
    create_table :tasks_tasked_placeholders do |t|
      t.timestamps null: false
    end
  end
end
