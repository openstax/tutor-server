class AddReadingProcessingInstructionsToContentBooks < ActiveRecord::Migration[4.2]
  def change
    add_column :content_books, :reading_processing_instructions, :jsonb, null: false, default: '[]'
  end
end
