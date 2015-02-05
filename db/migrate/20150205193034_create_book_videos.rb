class CreateBookVideos < ActiveRecord::Migration
  def change
    create_table :book_videos do |t|
      t.references :book, index: true
      t.references :video, index: true
      t.integer :number

      t.timestamps null: false
    end
  end
end
