class ChangeUrlIsPermalinkToImmutableInResources < ActiveRecord::Migration
  def change
    rename_column :resources, :url_is_permalink, :is_immutable
  end
end
