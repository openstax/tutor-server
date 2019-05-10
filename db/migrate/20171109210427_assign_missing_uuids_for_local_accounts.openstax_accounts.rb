# This migration comes from openstax_accounts (originally 10)
class AssignMissingUuidsForLocalAccounts < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'pgcrypto'

    OpenStax::Accounts::Account.where(uuid: nil).update_all('"uuid" = gen_random_uuid()')

    change_column :openstax_accounts_accounts, :uuid, :uuid, using: 'uuid::uuid',
                                                             default: 'gen_random_uuid()',
                                                             null: false
  end
end
