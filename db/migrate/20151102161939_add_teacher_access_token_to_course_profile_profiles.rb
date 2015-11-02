class AddTeacherAccessTokenToCourseProfileProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :teacher_access_token, :string

    reversible do |direction|
      direction.up do
        CourseProfile::Models::Profile.where(teacher_access_token: nil).find_each do |p|
          GenerateToken.apply!(record: p, attribute: :teacher_access_token)
        end

        change_column :course_profile_profiles, :teacher_access_token, :string, null: false
      end
    end
  end
end
