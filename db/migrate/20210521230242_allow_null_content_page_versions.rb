class AllowNullContentPageVersions < ActiveRecord::Migration[5.2]
  def change
    change_column_null :content_pages, :version, true
  end
end
