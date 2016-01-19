class DropFakeStores < ActiveRecord::Migration
  def up
    drop_table :fake_stores
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
