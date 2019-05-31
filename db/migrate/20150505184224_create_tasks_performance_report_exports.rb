class CreateTasksPerformanceReportExports < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_performance_report_exports do |t|
      t.references :entity_course, null: false, index: true,
                                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role, null: false,
                                 foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :export

      t.timestamps

      t.index [:entity_role_id, :entity_course_id],
              name: 'index_performance_report_exports_on_role_and_course'
    end
  end
end
