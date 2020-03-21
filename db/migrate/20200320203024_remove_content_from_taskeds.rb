class RemoveContentFromTaskeds < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_tasked_readings, :fragment_index, :integer

    Content::Models::Page.find_each do |page|
      page.fragments.each_with_index do |fragment, index|
        next unless fragment.respond_to? :to_html

        Tasks::Models::TaskedReading.joins(:task_step).where(
          task_step: { content_page_id: page.id },
          content: fragment.to_html
        ).update_all fragment_index: index
      end
    end

    change_column_null :tasks_tasked_readings, :fragment_index, false

    remove_column :tasks_tasked_readings, :content
    remove_column :tasks_tasked_exercises, :content
    remove_column :tasks_tasked_exercises, :context
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
