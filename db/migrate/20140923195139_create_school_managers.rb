class CreateSchoolManagers < ActiveRecord::Migration
  def change
    create_table :school_managers do |t|
      t.references :school, null: false
      t.references :user, null: false

      t.timestamps null: false

      t.index [:user_id, :school_id], unique: true
      t.index :school_id
    end

    add_foreign_key :school_managers, :schools, on_update: :cascade,
                                                on_delete: :cascade
    add_foreign_key :school_managers, :users, on_update: :cascade,
                                              on_delete: :cascade
  end
end
