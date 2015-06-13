class CreateTasksPerformanceReportExports < ActiveRecord::Migration
  def change
    create_table :tasks_performance_report_exports do |t|
      t.references :entity_course, index: true
      t.references :entity_role, index: true
      t.string :export
      t.timestamps
    end
    add_foreign_key :tasks_performance_report_exports, :entity_courses
    add_foreign_key :tasks_performance_report_exports, :entity_roles
  end
end
