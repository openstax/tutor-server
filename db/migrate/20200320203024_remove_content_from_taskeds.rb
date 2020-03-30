class RemoveContentFromTaskeds < ActiveRecord::Migration[5.2]
  def up
    change_column_null :tasks_tasked_readings, :content, true

    BackgroundMigrate.perform_later 'up', 20200330145448

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
