class AddRegistrationTokenToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :registration_token, :string

    reversible do |direction|
      direction.up do
        CourseProfile::Models::Profile.where(registration_token: nil).find_each do |p|
          GenerateToken.apply!(p, :registration_token)
        end

        change_column :course_profile_profiles, :registration_token, :string, null: false
      end
    end
  end
end
