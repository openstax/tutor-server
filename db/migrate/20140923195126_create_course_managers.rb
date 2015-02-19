class CreateCourseManagers < ActiveRecord::Migration
  def change
    create_table :course_managers do |t|
      t.references :course, null: false
      t.references :user, null: false

      t.timestamps null: false

      t.index [:user_id, :course_id], unique: true
      t.index :course_id
    end

    add_foreign_key :course_managers, :courses, on_update: :cascade,
                                                on_delete: :cascade
    add_foreign_key :course_managers, :users, on_update: :cascade,
                                              on_delete: :cascade
  end
end
