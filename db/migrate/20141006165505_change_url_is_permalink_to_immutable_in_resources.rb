class ChangeUrlIsPermalinkToImmutableInResources < ActiveRecord::Migration
  def change
    rename_column :resources, :url_is_permalink, :immutable
  end
end
