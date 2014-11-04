class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :url
      t.boolean :is_immutable
      t.text :content

      t.timestamps null: false
    end

    add_index :resources, :url, unique: true
  end
end
