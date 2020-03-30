class RemoveContentFromTaskeds < ActiveRecord::Migration[5.2]
  def up
    change_column_null :tasks_tasked_readings, :content, true

    # tasked_exercises don't have modified content at this time
    remove_column :tasks_tasked_exercises, :content
    remove_column :tasks_tasked_exercises, :context

    add_column :tasks_tasked_exercises, :content, :text
    add_column :tasks_tasked_exercises, :context, :text

    add_column :content_exercises, :question_answer_ids, :jsonb
    add_column :tasks_tasked_exercises, :answer_ids, :string, array: true

    BackgroundMigrate.perform_later 'up', 20200330145448
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
