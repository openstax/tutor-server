class RenameReadingTryAnotherPoolToReadingContextPool < ActiveRecord::Migration
  def change
    rename_column :content_pages, :content_reading_try_another_pool_id,
                                  :content_reading_context_pool_id
  end
end
