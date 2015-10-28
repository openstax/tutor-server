class AddCommentsToContentEcosystems < ActiveRecord::Migration
  def change
    add_column :content_ecosystems, :comments, :text
  end
end
