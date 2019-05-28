class AddMissingDoorkeeperForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key(
      :oauth_access_grants,
      :oauth_applications,
      column: :application_id
    )

    add_foreign_key(
      :oauth_access_tokens,
      :oauth_applications,
      column: :application_id
    )
  end
end
