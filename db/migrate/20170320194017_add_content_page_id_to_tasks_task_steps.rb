class AddContentPageIdToTasksTaskSteps < ActiveRecord::Migration
  def up
    add_column :tasks_task_steps, :content_page_id, :integer

    puts "Migrating #{Tasks::Models::TaskedExercise.unscoped.count} exercise steps"
    Tasks::Models::TaskStep.unscoped.update_all(
      <<-SQL.strip_heredoc
        content_page_id = content_exercises.content_page_id
          FROM tasks_tasked_exercises, content_exercises
          WHERE tasked_id = tasks_tasked_exercises.id
            AND tasked_type = 'Tasks::Models::TaskedExercise'
            AND content_exercises.id = tasks_tasked_exercises.content_exercise_id
      SQL
    )

    puts "Migrating #{Tasks::Models::TaskedReading.unscoped.count} reading steps"
    Tasks::Models::TaskStep.unscoped.update_all(
      <<-SQL.strip_heredoc
        content_page_id = content_pages.id
          FROM tasks_tasks, content_ecosystems, content_books, content_chapters, content_pages,
            tasks_tasked_readings
          WHERE tasked_id = tasks_tasked_readings.id
            AND tasked_type = 'Tasks::Models::TaskedReading'
            AND tasks_task_id = tasks_tasks.id
            AND tasks_tasks.content_ecosystem_id = content_ecosystems.id
            AND content_books.content_ecosystem_id = content_ecosystems.id
            AND content_chapters.content_book_id = content_books.id
            AND content_chapters.number = (tasks_tasked_readings.book_location::json->>0)::int
            AND content_pages.content_chapter_id = content_chapters.id
            AND content_pages.number = (tasks_tasked_readings.book_location::json->>1)::int
      SQL
    )

    puts "Migrating #{Tasks::Models::TaskStep.unscoped.count} remaining steps"
    Tasks::Models::TaskStep.unscoped.update_all(
      <<-SQL.strip_heredoc
        content_page_id = ts2.content_page_id
        FROM tasks_task_steps ts1, LATERAL (
          SELECT content_page_id
          FROM tasks_tasks, tasks_task_steps ts2
          WHERE tasks_tasks.id = ts1.tasks_task_id
          AND ts2.tasks_task_id = tasks_tasks.id
          AND ts2.content_page_id IS NOT NULL
          AND ts2.number < ts1.number
          ORDER BY ts2.number DESC
          LIMIT 1
        ) AS ts2
        WHERE tasks_task_steps.content_page_id IS NULL
          AND tasks_task_steps.id = ts1.id
      SQL
    )
  end

  def down
    remove_column :tasks_task_steps, :content_page_id
  end
end
