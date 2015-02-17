class CreateAssistants < ActiveRecord::Migration
  def change
    create_table :assistants do |t|
      t.string :name, null: false
      t.string :code_class_name, null: false
      t.string :task_plan_type, null: false

      t.timestamps null: false
    end

    add_index :assistants, :name, unique: true
    add_index :assistants, :code_class_name, unique: true
  end
end
