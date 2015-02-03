class CreateSchoolManagers < ActiveRecord::Migration
  def change
    create_table :school_managers do |t|
      t.references :school, null: false
      t.references :user, null: false

      t.timestamps null: false
    end

    add_index :school_managers, [:user_id, :school_id], unique: true
    add_index :school_managers, :school_id
  end
end
