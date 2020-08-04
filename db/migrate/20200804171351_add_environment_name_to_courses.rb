class AddEnvironmentNameToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :course_profile_courses, :environment_name, :string

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course.update_all(
          environment_name: Rails.application.secrets.environment_name
        )
      end
    end

    change_column_null :course_profile_courses, :environment_name, false
  end
end
