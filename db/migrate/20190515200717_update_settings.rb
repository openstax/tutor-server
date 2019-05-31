class UpdateSettings < ActiveRecord::Migration[5.2]
  def change
    remove_index :settings, column: %i(thing_type thing_id var), unique: true

    remove_column :settings, :thing_id, :integer
    remove_column :settings, :thing_type, :string, limit: 30

    add_index :settings, %i(var), unique: true
  end
end
