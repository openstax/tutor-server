class RemoveDuplicateContentFromTaskedReadings < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    # Clear the content column for all TaskedReadings that have verbatim copies of the book content
    Content::Models::Page.find_each do |page|
      Tasks::Models::TaskedReading.transaction do
        page.fragments.each_with_index do |fragment, index|
          next unless fragment.respond_to? :to_html

          Tasks::Models::TaskedReading.joins(:task_step).where(
            task_step: { content_page_id: page.id, fragment_index: index },
            content: fragment.to_html
          ).update_all content: nil
        end
      end
    end
  end

  def down
  end
end
