class CreateSalesforceUsers < ActiveRecord::Migration
  def change
    create_table :salesforce_users do |t|
      t.string :name
      t.string :uid
      t.string :oauth_token
      t.string :refresh_token
      t.string :instance_url
    end
  end
end
