class AddBakedFlagToBooks < ActiveRecord::Migration[4.2]
  def change
    add_column :content_books, :baked_at, :datetime
    add_column :content_books, :is_collated, :boolean, default: false
  end
end
