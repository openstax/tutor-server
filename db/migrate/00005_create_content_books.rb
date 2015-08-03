class CreateContentBooks < ActiveRecord::Migration
  def change
    create_table :content_books do |t|
      t.references :ecosystem_ecosystem, index: true, foreign_key: { on_update: :cascade,
                                                                     on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
