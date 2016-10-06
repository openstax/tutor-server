class AddStartAtAndEndAtToCourses < ActiveRecord::Migration
  LEGACY_COURSE_START_DATE = DateTime.parse('July 1st, 2015')
  LEGACY_COURSE_END_DATE   = DateTime.parse('July 1st, 2017') - 1.second

  def change
    add_column :course_profile_profiles, :starts_at, :datetime
    add_column :course_profile_profiles, :ends_at,   :datetime

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Profile.update_all(
          starts_at: LEGACY_COURSE_START_DATE, ends_at: LEGACY_COURSE_END_DATE
        )
      end
    end

    change_column_null :course_profile_profiles, :starts_at, false
    change_column_null :course_profile_profiles, :ends_at,   false
  end
end
