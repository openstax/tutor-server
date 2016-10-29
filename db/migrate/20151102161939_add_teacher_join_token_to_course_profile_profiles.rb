class AddTeacherJoinTokenToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :teacher_join_token, :string

    change_column_null :course_profile_profiles, :teacher_join_token, false

    add_index :course_profile_profiles, :teacher_join_token, unique: true
  end
end
