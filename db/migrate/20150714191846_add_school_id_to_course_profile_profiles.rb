class AddSchoolIdToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :course_detail_school_id, :integer
    add_index :course_profile_profiles, :course_detail_school_id
  end
end
