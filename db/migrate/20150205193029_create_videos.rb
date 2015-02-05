class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.references :resource, null: false

      t.timestamps null: false
    end

    add_index :videos, :resource_id, unique: true
  end
end
