class AddFileToTasksPerformanceBookExports < ActiveRecord::Migration
  def change
    add_column :tasks_performance_book_exports, :file, :string
  end
end
