class AllowNilIsCollege < ActiveRecord::Migration[4.2]
  def change
    change_column_null :course_profile_courses, :is_college, true
    change_column_default :course_profile_courses, :is_college, nil

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course
          .where(is_preview: false, is_college: false)
          .where("created_at >= '#{DateTime.new(2017, 6, 30).to_s(:db)}'")
          .update_all(is_college: nil)
      end

      dir.down do
        CourseProfile::Models::Course.where(is_college: nil).update_all(is_college: true)
      end
    end
  end
end
