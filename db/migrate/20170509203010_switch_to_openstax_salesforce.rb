class OldSfUser < ActiveRecord::Base
  self.table_name = :salesforce_users
end

class SwitchToOpenStaxSalesforce < ActiveRecord::Migration
  def up
    # Move SF user from native model to openstax_salesforce model
    old_sf_user = OldSfUser.first

    if old_sf_user.present?
      OpenStax::Salesforce::User.create!(
        name:          old_sf_user.name,
        uid:           old_sf_user.uid,
        oauth_token:   old_sf_user.oauth_token,
        refresh_token: old_sf_user.refresh_token,
        instance_url:  old_sf_user.instance_url
      )
    end

    # drop old SF user table
    drop_table :salesforce_users
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
