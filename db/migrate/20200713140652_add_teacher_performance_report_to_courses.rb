class AddTeacherPerformanceReportToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :course_profile_courses, :teacher_performance_report, :jsonb, array: true

    Tasks::FreezeEndedCourseTeacherPerformanceReports.set(queue: :migration).perform_later
  end
end
