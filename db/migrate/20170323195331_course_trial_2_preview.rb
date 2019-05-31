class CourseTrial2Preview < ActiveRecord::Migration[4.2]
  def change
    rename_column :course_profile_courses, :is_trial, :is_preview
  end
end
