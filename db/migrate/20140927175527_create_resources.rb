class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :url, null: false
      t.text :cached_content
      t.datetime :cache_expires_at
      t.datetime :cached_at
      t.string :etag

      t.timestamps null: false
    end

    add_index :resources, :url, unique: true
    add_index :resources, :cache_expires_at
  end
end
