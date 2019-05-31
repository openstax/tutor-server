class AddIsCollegeFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_profiles, :is_college, :boolean, default: false, null: false
    add_column :catalog_offerings, :is_normally_college, :boolean, default: false, null: false
  end
end
