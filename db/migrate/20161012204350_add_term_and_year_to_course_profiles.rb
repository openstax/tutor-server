class AddTermAndYearToCourseProfiles < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :term, :integer
    add_column :course_profile_profiles, :year, :integer

    reversible do |dir|
      dir.up do
        legacy_term = CourseProfile::Models::Profile.terms[:legacy]
        CourseProfile::Models::Profile.update_all term: legacy_term

        CourseProfile::Models::Profile.update_all 'year = EXTRACT(YEAR FROM created_at)'
      end
    end

    change_column_null :course_profile_profiles, :term, false
    change_column_null :course_profile_profiles, :year, false

    add_index :course_profile_profiles, [:year, :term]
  end
end
