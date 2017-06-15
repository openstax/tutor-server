class AddContentPageIdToTasksTaskSteps < ActiveRecord::Migration
  def up
    add_column :tasks_task_steps, :content_page_id, :integer

    Rails.logger.info { "Migrating #{Tasks::Models::TaskedExercise.unscoped.count} exercise steps" }
    Tasks::Models::TaskStep.unscoped.update_all(
      <<-SQL.strip_heredoc
        content_page_id = content_exercises.content_page_id
          FROM tasks_tasked_exercises
            INNER JOIN content_exercises
              ON content_exercises.id = tasks_tasked_exercises.content_exercise_id
          WHERE tasked_id = tasks_tasked_exercises.id
            AND tasked_type = 'Tasks::Models::TaskedExercise'
      SQL
    )

    Rails.logger.info { "Migrating #{Tasks::Models::TaskedReading.unscoped.count} reading steps" }
    Tasks::Models::TaskStep.unscoped.update_all(
      <<-SQL.strip_heredoc
        content_page_id = content_pages.id
        FROM tasks_task_steps ts
          INNER JOIN tasks_tasked_readings
            ON tasks_tasked_readings.id = ts.tasked_id
          INNER JOIN tasks_tasks
            ON tasks_tasks.id = ts.tasks_task_id
          INNER JOIN content_ecosystems
            ON content_ecosystems.id = tasks_tasks.content_ecosystem_id
          INNER JOIN content_books
            ON content_books.content_ecosystem_id = content_ecosystems.id
          INNER JOIN content_chapters
            ON content_chapters.content_book_id = content_books.id
          INNER JOIN content_pages
            ON content_pages.content_chapter_id = content_chapters.id
            AND content_pages.book_location = tasks_tasked_readings.book_location
        WHERE ts.id = tasks_task_steps.id
          AND tasks_task_steps.tasked_type = 'Tasks::Models::TaskedReading'
      SQL
    )

    Rails.logger.info { "Migrating #{Tasks::Models::TaskStep.unscoped.count} remaining steps" }
    Tasks::Models::TaskStep.unscoped.update_all(
      <<-SQL.strip_heredoc
        content_page_id = previous_step.content_page_id
        FROM tasks_task_steps current_step
          CROSS JOIN LATERAL (
            SELECT content_page_id
            FROM tasks_task_steps previous_step
            WHERE previous_step.tasks_task_id = current_step.tasks_task_id
            AND previous_step.content_page_id IS NOT NULL
            AND previous_step.number < current_step.number
            ORDER BY previous_step.number DESC
            LIMIT 1
          ) AS previous_step
        WHERE tasks_task_steps.content_page_id IS NULL
          AND current_step.id = tasks_task_steps.id
      SQL
    )
  end

  def down
    remove_column :tasks_task_steps, :content_page_id
  end
end
