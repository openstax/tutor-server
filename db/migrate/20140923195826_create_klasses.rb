class CreateKlasses < ActiveRecord::Migration
  def change
    create_table :klasses do |t|
      t.references :course, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.datetime :visible_at
      t.datetime :invisible_at
      t.string :time_zone
      t.text :approved_emails
      t.boolean :allow_student_custom_identifier

      t.timestamps null: false

      t.index [:ends_at, :starts_at]
      t.index [:invisible_at, :visible_at]
      t.index :course_id
    end

    add_foreign_key :klasses, :courses, on_update: :cascade,
                                        on_delete: :cascade
  end
end
