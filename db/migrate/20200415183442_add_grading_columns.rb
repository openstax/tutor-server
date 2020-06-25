class AddGradingColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasked_exercises, :grader_points, :float
    add_column :tasks_tasked_exercises, :grader_comments, :text
    add_column :tasks_tasked_exercises, :last_graded_at, :datetime
    add_column :tasks_tasked_exercises, :published_points, :float
    add_column :tasks_tasked_exercises, :published_comments, :text

    add_column :tasks_tasks, :grades_last_published_at, :datetime
  end
end
