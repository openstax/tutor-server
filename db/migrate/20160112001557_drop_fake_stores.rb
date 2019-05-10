class DropFakeStores < ActiveRecord::Migration[4.2]
  def up
    drop_table :fake_stores
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
