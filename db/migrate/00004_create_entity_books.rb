class CreateEntityBooks < ActiveRecord::Migration
  def change
    create_table :entity_books do |t|
      t.timestamps null: false
    end
  end
end
