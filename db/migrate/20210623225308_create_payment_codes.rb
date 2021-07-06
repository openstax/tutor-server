class CreatePaymentCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_codes do |t|
      t.string :code
      t.datetime :redeemed_at
      t.references :course_membership_student

      t.timestamps
      t.index :code, unique: true
    end
  end
end
