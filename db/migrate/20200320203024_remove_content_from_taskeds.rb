class RemoveContentFromTaskeds < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_tasked_readings, :fragment_index, :integer
    change_column_null :tasks_tasked_readings, :content, true

    # First set the fragment_index for all tasked_readings with content matching some page fragment
    Content::Models::Page.find_each do |page|
      page.fragments.each_with_index do |fragment, index|
        next unless fragment.respond_to? :to_html

        Tasks::Models::TaskedReading.joins(:task_step).where(
          task_step: { content_page_id: page.id },
          content: fragment.to_html
        ).update_all fragment_index: index, content: nil
      end
    end

    # If the content was modified, attempt to copy it from the previous step with the same page
    Tasks::Models::TaskedReading.update_all(
      <<~UPDATE_SQL
        "fragment_index" = (
          SELECT "previous_task_step"."fragment_index" + 1
          FROM "tasks_task_steps" AS "previous_task_step"
          WHERE "previous_task_step"."content_page_id" = "tasks_task_steps"."content_page_id"
            AND "previous_task_step"."number" = "tasks_task_steps"."number" - 1
        )
        FROM "tasks_task_steps"
        WHERE "tasks_tasked_readings"."fragment_index" IS NULL
          AND "tasks_task_steps"."tasked_id" = "tasks_tasked_readings"."id"
          AND "tasks_task_steps"."tasked_type" = 'Tasks::Models::TaskedReading'
      UPDATE_SQL
    )

    # If no previous step with the same page, assume this is the first step in the page
    Tasks::Models::TaskedReading.where(fragment_index: nil).update_all fragment_index: 0

    change_column_null :tasks_tasked_readings, :fragment_index, false

    # tasked_exercises don't have modified content at this time
    remove_column :tasks_tasked_exercises, :content
    remove_column :tasks_tasked_exercises, :context

    add_column :tasks_tasked_exercises, :content, :text
    add_column :tasks_tasked_exercises, :context, :text

    add_column :content_exercises, :question_answer_ids, :jsonb
    add_column :tasks_tasked_exercises, :answer_ids, :string, array: true

    Content::Models::Exercise.preload(:tasked_exercises).find_each do |exercise|
      exercise.update_attribute :question_answer_ids, exercise.parser.question_answer_ids

      exercise.tasked_exercises.group_by(&:question_index).each do |question_index, tes|
        Tasks::Models::TaskedExercise.where(id: tes.map(&:id)).update_all(
          answer_ids: exercise.question_answer_ids[question_index]
        )
      end
    end

    change_column_null :content_exercises, :question_answer_ids, false
    change_column_null :tasks_tasked_exercises, :answer_ids, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
