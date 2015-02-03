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
    end

    add_index :klasses, [:ends_at, :starts_at]
    add_index :klasses, [:invisible_at, :visible_at]
    add_index :klasses, :course_id
  end
end
