class CourseTrial2Demo < ActiveRecord::Migration
  def change
    rename_column :course_profile_courses, :is_trial, :is_demo
  end
end
