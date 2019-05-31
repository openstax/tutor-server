class CreateContentEcosystems < ActiveRecord::Migration[4.2]
  def change
    create_table :content_ecosystems do |t|
      t.string :title, null: false

      t.timestamps null: false

      t.index :title
      t.index :created_at
    end
  end
end
