class CreateCourseProfileProfiles < ActiveRecord::Migration
  def change
    create_table :course_profile_profiles do |t|
      t.integer :entity_course_id, null: false
      t.string :name,   null: false
      t.timestamps null: false

      t.index :entity_course_id, unique: true
      t.index :name
    end

     add_foreign_key :course_profile_profiles, :entity_courses
  end
end
