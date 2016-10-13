class AddStartAtAndEndAtToCourses < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :starts_at, :datetime
    add_column :course_profile_profiles, :ends_at,   :datetime

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Profile.update_all(
          starts_at: TermYear::LEGACY_TERM_STARTS_AT, ends_at: TermYear::LEGACY_TERM_ENDS_AT
        )
      end
    end

    change_column_null :course_profile_profiles, :starts_at, false
    change_column_null :course_profile_profiles, :ends_at,   false
  end
end
