class CreateTasksAssistants < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_assistants do |t|
      t.string :name, null: false
      t.string :code_class_name, null: false

      t.timestamps null: false

      t.index :name, unique: true
      t.index :code_class_name, unique: true
    end
  end
end
