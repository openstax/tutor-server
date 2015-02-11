class CreateAssistants < ActiveRecord::Migration
  def change
    create_table :assistants do |t|
      t.references :study
      t.string :code_class_name, null: false
      t.text :settings
      t.text :data

      t.timestamps null: false
    end

    add_index :assistants, :study_id
    add_index :assistants, :code_class_name
  end
end
