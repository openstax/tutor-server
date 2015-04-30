class CreateEducators < ActiveRecord::Migration
  def change
    create_table :educators do |t|
      t.references :course, null: false
      t.references :user, null: false

      t.timestamps null: false

      t.index [:user_id, :course_id], unique: true
      t.index :course_id
    end

    add_foreign_key :educators, :courses, on_update: :cascade,
                                          on_delete: :cascade
    add_foreign_key :educators, :user_profile_profiles, column: :user_id, on_update: :cascade,
                                                                          on_delete: :cascade
  end
end
