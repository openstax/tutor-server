class CourseTrial2Preview < ActiveRecord::Migration
  def change
    rename_column :course_profile_courses, :is_trial, :is_preview
  end
end
