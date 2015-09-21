class Admin::UsersUpdate
  lev_handler

  ALLOWED_ATTRIBUTES = ['username', 'first_name', 'last_name', 'full_name', 'title']

  paramify :user do
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
  end

  protected

  def authorized?
    true
  end

  # The :profile option is required
  def handle
    account = options[:profile].account
    outputs[:account] = account

    # Validate the account but do not call save
    # Use update_columns to prevent save callbacks that would send updates to Accounts
    account.assign_attributes(user_params.attributes.slice(*ALLOWED_ATTRIBUTES))
    account.valid?
    transfer_errors_from account, {type: :verbatim}, true
    account.update_columns(user_params.attributes.slice(*ALLOWED_ATTRIBUTES))
  end
end
