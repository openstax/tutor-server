class CreateSalesforceAttachedRecord < ActiveRecord::Migration
  def change
    create_table :salesforce_attached_records do |t|
      t.string :tutor_gid
      t.string :salesforce_class_name
      t.string :salesforce_id

      t.index :tutor_gid
      t.index [:salesforce_id, :salesforce_class_name, :tutor_gid],
              unique: true, name: 'salesforce_attached_record_tutor_gid'
    end
  end
end
