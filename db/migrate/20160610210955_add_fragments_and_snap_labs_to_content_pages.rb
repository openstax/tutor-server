class AddFragmentsAndSnapLabsToContentPages < ActiveRecord::Migration[4.2]
  def change
    # This migration has been split in 2 so that it works with the model changes
    # End result should be the same regardless

    add_column :content_pages, :fragments, :string, array: true
    add_column :content_pages, :snap_labs, :jsonb

    # Rest of this migration now happens after the column type change migration
  end
end
