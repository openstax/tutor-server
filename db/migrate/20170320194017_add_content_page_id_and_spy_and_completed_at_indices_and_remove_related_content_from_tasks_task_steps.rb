class AddContentPageIdAndSpyAndCompletedAtIndicesAndRemoveRelatedContentFromTasksTaskSteps < ActiveRecord::Migration
  CONFLICTING_MIGRATION_VERSION = 20170508171927

  def up
    # Undo the conflicting migration, if already done
    migration_paths = ActiveRecord::Migrator.migrations_paths
    conflicting_migrations = ActiveRecord::Migrator.down(migration_paths) do |migration|
      migration.version == CONFLICTING_MIGRATION_VERSION
    end

    # https://dba.stackexchange.com/a/52531
    query = <<-SQL.strip_heredoc
      SET LOCAL work_mem = '128 MB'; -- just for this transaction
      SET LOCAL maintenance_work_mem = '512 MB';
      SET LOCAL temp_buffers = '6 GB';

      LOCK TABLE tasks_task_steps IN SHARE MODE;

      WITH steps_with_content_page_id AS (
        SELECT tasks_task_steps.*,
          CASE tasked_type
          WHEN 'Tasks::Models::TaskedExercise'
          THEN
            (
              SELECT content_exercises.content_page_id
              FROM tasks_tasked_exercises
                INNER JOIN content_exercises
                  ON content_exercises.id = tasks_tasked_exercises.content_exercise_id
              WHERE tasks_tasked_exercises.id = tasked_id
            )
          WHEN 'Tasks::Models::TaskedReading'
          THEN
            (
              SELECT content_pages.id
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
            )
          END AS content_page_id
          FROM tasks_task_steps
          ORDER BY id
      )
      SELECT id,
        tasks_task_id,
        tasked_id,
        tasked_type,
        number,
        first_completed_at,
        last_completed_at,
        group_type,
        created_at,
        updated_at,
        deleted_at,
        related_exercise_ids,
        labels,
        '{}'::text AS spy,
        COALESCE(
          current_step.content_page_id,
          (
            SELECT previous_step.content_page_id
            FROM steps_with_content_page_id previous_step
            WHERE current_step.group_type != 2 -- content_page_id = null for SPE placeholders
            AND previous_step.tasks_task_id = current_step.tasks_task_id
            AND previous_step.content_page_id IS NOT NULL
            AND previous_step.number < current_step.number
            ORDER BY previous_step.number DESC
            LIMIT 1
          )
        ) AS content_page_id
      INTO task_steps_temp
      FROM steps_with_content_page_id current_step;

      ALTER TABLE task_steps_temp
        ALTER COLUMN id SET DEFAULT nextval('tasks_task_steps_id_seq'::regclass),
        ALTER COLUMN id SET NOT NULL,
        ALTER COLUMN tasks_task_id SET NOT NULL,
        ALTER COLUMN tasked_id SET NOT NULL,
        ALTER COLUMN tasked_type SET NOT NULL,
        ALTER COLUMN number SET NOT NULL,
        ALTER COLUMN group_type SET DEFAULT 0,
        ALTER COLUMN group_type SET NOT NULL,
        ALTER COLUMN created_at SET NOT NULL,
        ALTER COLUMN updated_at SET NOT NULL,
        ALTER COLUMN related_exercise_ids SET DEFAULT '[]'::text,
        ALTER COLUMN related_exercise_ids SET NOT NULL,
        ALTER COLUMN labels SET DEFAULT '[]'::text,
        ALTER COLUMN labels SET NOT NULL,
        ALTER COLUMN spy SET DEFAULT '{}'::text,
        ALTER COLUMN spy SET NOT NULL;

      ALTER SEQUENCE tasks_task_steps_id_seq OWNED BY task_steps_temp.id;

      DROP TABLE tasks_task_steps;
      ALTER TABLE task_steps_temp RENAME TO tasks_task_steps;

      ALTER TABLE tasks_task_steps
        ADD CONSTRAINT tasks_task_steps_pkey PRIMARY KEY (id),
        ADD CONSTRAINT fk_rails_a7b925659a FOREIGN KEY (tasks_task_id) REFERENCES tasks_tasks(id)
          ON UPDATE CASCADE ON DELETE CASCADE;

      CREATE INDEX index_tasks_task_steps_on_deleted_at
        ON tasks_task_steps
        USING btree (deleted_at);

      CREATE INDEX index_tasks_task_steps_on_first_completed_at
        ON tasks_task_steps
        USING btree (first_completed_at);

      CREATE INDEX index_tasks_task_steps_on_last_completed_at
        ON tasks_task_steps
        USING btree (last_completed_at);

      CREATE UNIQUE INDEX index_tasks_task_steps_on_tasked_id_and_tasked_type
        ON tasks_task_steps
        USING btree (tasked_id, tasked_type);

      CREATE UNIQUE INDEX index_tasks_task_steps_on_tasks_task_id_and_number
        ON tasks_task_steps
        USING btree (tasks_task_id, number);

      ANALYZE tasks_task_steps;
    SQL

    ActiveRecord::Base.connection.execute query

    # Redo the conflicting migrations, if any
    conflicting_migrations.each { |migration| migration.migrate :up }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
