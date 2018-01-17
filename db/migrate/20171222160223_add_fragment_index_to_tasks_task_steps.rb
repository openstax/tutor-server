class AddFragmentIndexToTasksTaskSteps < ActiveRecord::Migration
  def change
    add_column :tasks_task_steps, :fragment_index, :integer

    reversible do |dir|
      dir.up do
        reading_type = Tasks::Models::Task.task_types[:reading]
        Tasks::Models::TaskStep.update_all(
          <<-UPDATE_SQL.strip_heredoc
            "fragment_index" = "steps_with_row_number"."row_number"
            FROM (
              SELECT "steps_with_row_number"."id",
                     "steps_with_row_number"."tasks_task_id",
                     ROW_NUMBER() OVER (
                       PARTITION BY "tasks_task_id", "content_page_id" ORDER BY "number"
                     ) AS "row_number"
              FROM "tasks_task_steps" "steps_with_row_number"
            ) "steps_with_row_number"
            INNER JOIN "tasks_tasks"
              ON "tasks_tasks"."id" = "steps_with_row_number"."tasks_task_id"
            WHERE "steps_with_row_number"."id" = "tasks_task_steps"."id"
              AND "tasks_tasks"."task_type" = #{reading_type}
          UPDATE_SQL
        )

        # Adjust fragment_indices up for exercises that were combined
        # with the previous fragment due to the requires-context tag
        # We don't actually adjust the exercises themselves,
        # just the steps that come after them and that are from the same page
        requires_context = Content::Models::Tag.tag_types[:requires_context]
        Tasks::Models::TaskedExercise.joins(exercise: :tags)
                                     .where(content_tags: { tag_type: requires_context })
                                     .preload(:task_step, exercise: :page)
                                     .find_each do |te|
          exercise = te.exercise
          task_step = te.task_step
          next if task_step.nil?

          fragment_index = task_step.fragment_index
          next if fragment_index.nil?

          fragment = exercise.page.fragments[fragment_index]
          next unless fragment.respond_to?(:to_html) &&
                      exercise.context.present? &&
                      exercise.context.include?(fragment.to_html)

          Tasks::Models::TaskStep.where(
            tasks_task_id: task_step.tasks_task_id, content_page_id: task_step.content_page_id
          )
          .where("\"number\" > #{task_step.number}")
          .update_all('"fragment_index" = "fragment_index" + 1')
        end
      end
    end
  end
end
