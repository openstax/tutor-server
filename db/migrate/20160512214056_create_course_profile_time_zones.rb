class CreateCourseProfileTimeZones < ActiveRecord::Migration
  def change
    create_table :course_profile_time_zones do |t|
      t.string :name, null: false, index: true

      t.timestamps null: false
    end
  end
end
