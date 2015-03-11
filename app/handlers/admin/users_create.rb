class Admin::UsersCreate
  lev_handler

  paramify :user do
    attribute :username, type: String
    attribute :password, type: String
    validates :username, presence: true
    validates :password, presence: true
  end

  uses_routine Domain::CreateAccount,
               translations: { outputs: { type: :verbatim } },
               as: :create_account

  protected

  def authorized?
    true
  end

  def handle
    run(:create_account, user_params)
  end
end
