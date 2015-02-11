class CreateExercises < ActiveRecord::Migration
  def change
    create_table :exercises do |t|
      t.references :resource, null: false
      t.string :title

      t.timestamps null: false
    end

    add_index :exercises, :resource_id, unique: true
    add_index :exercises, :title

    add_foreign_key :exercises, :resources, on_update: :cascade,
                                            on_delete: :cascade
  end
end
