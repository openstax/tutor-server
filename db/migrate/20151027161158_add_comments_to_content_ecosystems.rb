class AddCommentsToContentEcosystems < ActiveRecord::Migration[4.2]
  def change
    add_column :content_ecosystems, :comments, :text
  end
end
