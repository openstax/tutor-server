class AddAppearanceCodeToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :appearance_code, :string
  end
end
