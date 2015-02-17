class CreateKlassAssistants < ActiveRecord::Migration
  def change
    create_table :klass_assistants do |t|
      t.references :klass, null: false
      t.references :assistant, null: false
      t.text :settings
      t.text :data

      t.timestamps null: false
    end

    add_index :klass_assistants, [:klass_id, :assistant_id], unique: true
    add_index :klass_assistants, :assistant_id

    add_foreign_key :klass_assistants, :klasses
    add_foreign_key :klass_assistants, :assistants
  end
end
