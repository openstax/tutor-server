class CreateUserCustomerServices < ActiveRecord::Migration[4.2]
  def change
    create_table :user_customer_services do |t|
      t.references :user_profile, null: false,
                                  index: { unique: true },
                                  foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
