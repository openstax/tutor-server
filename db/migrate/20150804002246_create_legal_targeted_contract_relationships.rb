class CreateLegalTargetedContractRelationships < ActiveRecord::Migration[4.2]
  def change
    create_table :legal_targeted_contract_relationships do |t|
      t.string :child_gid, null: false
      t.string :parent_gid, null: false

      t.timestamps null: false

      t.index [:child_gid, :parent_gid], unique: true, name: 'legal_targeted_contracts_rship_child_parent'
      t.index [:parent_gid], name: 'legal_targeted_contracts_rship_parent'
    end
  end
end
