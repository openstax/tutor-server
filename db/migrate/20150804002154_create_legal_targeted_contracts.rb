class CreateLegalTargetedContracts < ActiveRecord::Migration[4.2]
  def change
    create_table :legal_targeted_contracts do |t|
      t.string :target_gid, null: false
      t.string :target_name, null: false
      t.string :contract_name, null: false
      t.text :masked_contract_names
      t.boolean :is_proxy_signed, default: false
      t.boolean :is_end_user_visible, default: true

      t.timestamps null: false

      t.index [:target_gid], name: 'legal_targeted_contracts_target'
    end
  end
end
