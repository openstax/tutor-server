class CreateLmsUser < ActiveRecord::Migration[4.2]
  def change
    create_table :lms_users do |t|
      t.string :lti_user_id, null: false, index: :unique

      t.references :openstax_accounts_accounts, index: :unique
    end
  end
end
