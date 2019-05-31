class CreateContentAnalysts < ActiveRecord::Migration[4.2]
  def change
    create_table :user_profile_content_analysts do |t|
      t.references :user_profile_profile, null: false,
                                          index: { unique: true },
                                          foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
