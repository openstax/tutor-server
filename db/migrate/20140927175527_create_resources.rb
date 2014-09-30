class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :url
      t.boolean :url_is_permalink
      t.text :content

      t.timestamps null: false
    end
  end
end
