class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :title, null: false
      t.string :version, null: false, default: '1'
      t.string :url, null: false
      t.text :cached_content
      t.datetime :cache_expires_at

      t.timestamps null: false
    end

    add_index :resources, [:title, :version], unique: true
    add_index :resources, :url, unique: true
  end
end
