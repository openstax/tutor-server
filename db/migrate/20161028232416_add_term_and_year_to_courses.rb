class AddTermAndYearToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :term, :integer
    add_column :course_profile_courses, :year, :integer

    reversible do |dir|
      dir.up do
        legacy_term = CourseProfile::Models::Course.terms[:legacy]
        CourseProfile::Models::Course.unscoped.update_all term: legacy_term

        CourseProfile::Models::Course.unscoped.update_all 'year = EXTRACT(YEAR FROM created_at)'
      end
    end

    change_column_null :course_profile_courses, :term, false
    change_column_null :course_profile_courses, :year, false

    add_index :course_profile_courses, [:year, :term]
  end
end
