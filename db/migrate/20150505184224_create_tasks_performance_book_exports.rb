class CreateTasksPerformanceBookExports < ActiveRecord::Migration
  def change
    create_table :tasks_performance_book_exports do |t|
      t.string :filename
      t.references :entity_course, index: true
      t.references :entity_role, index: true
      t.timestamps
    end
    add_foreign_key :tasks_performance_book_exports, :entity_courses
    add_foreign_key :tasks_performance_book_exports, :entity_roles
  end
end
