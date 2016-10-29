class AddStartAtAndEndAtToCourses < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :starts_at, :datetime
    add_column :course_profile_courses, :ends_at,   :datetime

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course.update_all(
          starts_at: TermYear::LEGACY_TERM_STARTS_AT, ends_at: TermYear::LEGACY_TERM_ENDS_AT
        )
      end
    end

    change_column_null :course_profile_courses, :starts_at, false
    change_column_null :course_profile_courses, :ends_at,   false
  end
end
