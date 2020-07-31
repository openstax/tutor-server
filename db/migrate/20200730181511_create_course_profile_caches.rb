class CreateCourseProfileCaches < ActiveRecord::Migration[5.2]
  def change
    create_table :course_profile_caches do |t|
      t.references :course_profile_course, null: false,
                                           foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.jsonb :teacher_performance_report, array: true, null: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course.where.not(
          teacher_performance_report: nil
        ).find_each do |course|
          CourseProfile::Models::Cache.create!(
            course: course,
            teacher_performance_report: course.read_attribute(:teacher_performance_report)
          )
        end
      end

      dir.down do
        CourseProfile::Models::Cache.preload(:course).find_each do |cache|
          cache.course.update_attribute(
            :teacher_performance_report, cache.teacher_performance_report
          )
        end
      end
    end

    remove_column :course_profile_courses, :teacher_performance_report, :jsonb, array: true
  end
end
