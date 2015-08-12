class CreateContentEcosystems < ActiveRecord::Migration
  def change
    create_table :content_ecosystems do |t|
      t.string :title, null: false

      t.timestamps null: false

      t.index :title
    end
  end
end
