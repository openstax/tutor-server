class AddAppearanceCodeToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :appearance_code, :string

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Profile.find_each do |profile|
          profile.update_attribute(:appearance_code, profile.offering.try(:appearance_code))
        end
      end
    end
  end
end
