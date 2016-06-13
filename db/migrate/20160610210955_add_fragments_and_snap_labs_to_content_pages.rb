class AddFragmentsAndSnapLabsToContentPages < ActiveRecord::Migration
  def change
    add_column :content_pages, :fragments, :string, array: true
    add_column :content_pages, :snap_labs, :jsonb

    reversible{ |dir| dir.up { Content::Models::Page.find_each(batch_size: 100, &:save!) } }

    change_column_null :content_pages, :fragments, false
    change_column_null :content_pages, :snap_labs, false
  end
end
