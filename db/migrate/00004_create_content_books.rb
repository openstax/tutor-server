class CreateContentBooks < ActiveRecord::Migration
  def change
    create_table :content_books do |t|
      t.timestamps null: false
    end
  end
end
