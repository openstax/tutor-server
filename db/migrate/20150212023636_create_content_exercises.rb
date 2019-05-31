class CreateContentExercises < ActiveRecord::Migration[4.2]
  def change
    create_table :content_exercises do |t|
      t.resource
      t.references :content_page, null: false,
                                  index: true,
                                  foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.integer :number, null: false
      t.integer :version, null: false
      t.string :title

      t.timestamps null: false

      t.resource_index
      t.index [:number, :version]
      t.index :title
    end
  end
end
