class CreateCourseManagers < ActiveRecord::Migration
  def change
    create_table :course_managers do |t|
      t.references :course, null: false
      t.references :user, null: false

      t.timestamps null: false
    end

    add_index :course_managers, :course_id
    add_index :course_managers, :user_id
    add_index :course_managers, [:user_id, :course_id], unique: true
  end
end
