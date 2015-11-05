class AddTeacherAccessTokenToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :teacher_access_token, :string

    reversible do |direction|
      direction.up do
        # the before_validation callback will apply the token
        CourseProfile::Models::Profile.where(teacher_access_token: nil).find_each(&:save)

        change_column :course_profile_profiles, :teacher_access_token, :string, null: false
      end
    end
  end
end
