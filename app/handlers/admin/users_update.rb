class Admin::UsersUpdate
  ALLOWED_ATTRIBUTES = ['username', 'first_name', 'last_name', 'full_name', 'title']

  lev_handler uses: [{ name: User::SetAdministratorState, as: :set_administrator },
                     { name: User::SetCustomerServiceState, as: :set_customer_service },
                     { name: User::SetContentAnalystState, as: :set_content_analyst }]

  paramify :user do
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :administrator, type: boolean
    attribute :customer_service, type: boolean
    attribute :content_analyst, type: boolean
  end

  protected

  def authorized?
    true
  end

  # The :profile option is required
  def handle
    set(user: options[:user], account: options[:user].account)

    # Validate the account but do not call save
    # Use update_columns to prevent save callbacks that would send updates to Accounts
    result.account.assign_attributes(user_params.attributes.slice(*ALLOWED_ATTRIBUTES))
    result.account.valid?
    transfer_errors_from result.account, {type: :verbatim}, true
    result.account.update_columns(user_params.attributes.slice(*ALLOWED_ATTRIBUTES))

    run(:set_administrator, user: result.user, administrator: user_params.administrator)
    run(:set_customer_service, user: result.user, customer_service: user_params.customer_service)
    run(:set_content_analyst, user: result.user, content_analyst: user_params.content_analyst)
  end
end
