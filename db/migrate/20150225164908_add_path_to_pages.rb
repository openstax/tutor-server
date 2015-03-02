class AddPathToPages < ActiveRecord::Migration
  def change
    add_column :content_pages, :path, :string
  end
end
