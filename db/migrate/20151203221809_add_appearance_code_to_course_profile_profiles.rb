class AddAppearanceCodeToCourseProfileProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_profiles, :appearance_code, :string
  end
end
