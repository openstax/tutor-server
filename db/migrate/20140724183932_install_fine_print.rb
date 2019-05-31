# This migration comes from fine_print (originally 0)
class InstallFinePrint < ActiveRecord::Migration[4.2]
  def change
    create_table :fine_print_contracts do |t|
      t.string :name, :null => false
      t.integer :version
      t.string :title, :null => false
      t.text :content, :null => false

      t.timestamps null: false

      t.index [:name, :version], :unique => true
    end

    create_table :fine_print_signatures do |t|
      t.belongs_to :contract, :null => false
      t.belongs_to :user, :polymorphic => true, :null => false
      t.index [:user_id, :user_type, :contract_id],
              :name => 'index_fine_print_signatures_on_u_id_and_u_type_and_c_id',
              :unique => true

      t.timestamps null: false

      t.index :contract_id
    end
  end
end
