class AddSchoolIdToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :school_district_school_id, :integer
    add_index :course_profile_profiles, :school_district_school_id
  end
end
