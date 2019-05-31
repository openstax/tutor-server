class RenameTeacherJoinTokenTeachToken < ActiveRecord::Migration[4.2]
  def change
    remove_index :course_profile_profiles, :teacher_join_token
    rename_column :course_profile_profiles, :teacher_join_token, :teach_token
    add_index :course_profile_profiles, :teach_token, unique: true
  end
end
