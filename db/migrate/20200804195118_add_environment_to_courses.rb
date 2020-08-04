class AddEnvironmentToCourses < ActiveRecord::Migration[5.2]
  def change
    add_reference :course_profile_courses, :environment, index: true,
                  foreign_key: { on_update: :cascade, on_delete: :restrict }

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course.update_all environment_id: Environment.current.id
      end
    end

    change_column_null :course_profile_courses, :environment_id, false
  end
end
