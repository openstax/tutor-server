class AddBakedFlagToBooks < ActiveRecord::Migration
  def change
    add_column :content_books, :baked, :datetime
  end
end
