class AddArchiveVersionToContentBooks < ActiveRecord::Migration[5.2]
  def change
    add_column :content_books, :archive_version, :string
  end
end
