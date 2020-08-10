class CreateEnvironments < ActiveRecord::Migration[5.2]
  def change
    create_table :environments do |t|
      t.string :name, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
