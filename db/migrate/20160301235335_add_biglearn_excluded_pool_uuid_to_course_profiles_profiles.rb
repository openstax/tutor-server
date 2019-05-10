class AddBiglearnExcludedPoolUuidToCourseProfilesProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_profiles, :biglearn_excluded_pool_uuid, :string
  end
end
