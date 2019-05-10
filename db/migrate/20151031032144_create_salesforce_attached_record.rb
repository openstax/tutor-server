class CreateSalesforceAttachedRecord < ActiveRecord::Migration[4.2]
  def change
    create_table :salesforce_attached_records do |t|
      t.string :tutor_gid, null: false
      t.string :salesforce_class_name, null: false
      t.string :salesforce_id, null: false
      t.timestamps

      t.index :tutor_gid
      t.index [:salesforce_id, :salesforce_class_name, :tutor_gid],
              unique: true, name: 'salesforce_attached_record_tutor_gid'
    end
  end
end
