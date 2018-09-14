class DropSalesforceAttachedRecords < ActiveRecord::Migration
  def up
    drop_table :salesforce_attached_records
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
