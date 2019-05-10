class AddIsDemoToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :is_trial, :boolean

    change_column_null :course_profile_courses, :is_trial, false, false
  end
end
