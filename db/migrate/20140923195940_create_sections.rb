class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.references :course, null: false
      t.string :name

      t.timestamps null: false

      t.index [:name, :course_id], unique: true
      t.index :course_id
    end

    add_foreign_key :sections, :courses, on_update: :cascade,
                                         on_delete: :cascade
  end
end
