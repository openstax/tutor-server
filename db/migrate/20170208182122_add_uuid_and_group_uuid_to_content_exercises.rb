class AddUuidAndGroupUuidToContentExercises < ActiveRecord::Migration
  def change
    enable_extension 'pgcrypto'

    add_column :content_exercises, :uuid, :uuid, null: false, index: true
    add_column :content_exercises, :group_uuid, :uuid, null: false

    add_index :content_exercises, [:group_uuid, :version]
  end
end
