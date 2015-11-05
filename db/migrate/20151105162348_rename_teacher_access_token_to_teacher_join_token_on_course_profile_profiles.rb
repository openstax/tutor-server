class RenameTeacherAccessTokenToTeacherJoinTokenOnCourseProfileProfiles < ActiveRecord::Migration
  def change
    rename_column :course_profile_profiles, :teacher_access_token, :teacher_join_token
  end
end
