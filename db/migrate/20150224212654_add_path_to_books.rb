class AddPathToBooks < ActiveRecord::Migration
  def change
    add_column :books, :path, :string
  end
end
