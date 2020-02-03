class Admin::UsersCreate
  ACCOUNT_PARAMS = [
    :username, :password, :first_name, :last_name, :full_name, :title, :email, :role
  ]

  lev_handler

  uses_routine User::FindOrCreateUser, translations: { outputs: { type: :verbatim } },
                                       as: :find_or_create_user
  uses_routine User::SetAdministratorState, as: :set_administrator
  uses_routine User::SetCustomerSupportState, as: :set_customer_support
  uses_routine User::SetContentAnalystState, as: :set_content_analyst
  uses_routine User::SetResearcherState, as: :set_researcher

  paramify :user do
    attribute :username, type: String
    attribute :password, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :email, type: String
    attribute :role, type: String
    attribute :administrator, type: boolean
    attribute :customer_support, type: boolean
    attribute :content_analyst, type: boolean
    attribute :researcher, type: boolean

    validates :username, presence: true
    validates :password, presence: true
    validates :first_name, presence: true
    validates :last_name, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    account_params = user_params.attributes.symbolize_keys.slice(*ACCOUNT_PARAMS)
    account = OpenStax::Accounts::FindOrCreateAccount.call(account_params).outputs.account

    fatal_error(
      code: :username_already_exists,
      message: "A user with username \"#{user_params.username}\" already exists."
    ) if ::User::Models::Profile.where(account_id: account.id).exists?

    outputs.user = ::User::Models::Profile.create(account_id: account.id)

    run(:set_administrator, user: outputs.user, administrator: user_params.administrator)
    run(:set_customer_support, user: outputs.user, customer_support: user_params.customer_support)
    run(:set_content_analyst, user: outputs.user, content_analyst: user_params.content_analyst)
    run(:set_researcher, user: outputs.user, researcher: user_params.researcher)
  end
end
