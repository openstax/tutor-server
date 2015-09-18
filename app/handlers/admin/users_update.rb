class Admin::UsersUpdate
  lev_handler

  ALLOWED_ATTRIBUTES = ['username', 'first_name', 'last_name', 'full_name', 'title']

  paramify :user do
    attribute :id, type: Integer
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String

    validates :username, presence: true
    validates :first_name, presence: true
    validates :last_name, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    profile = UserProfile::Models::Profile.find(user_params.id)
    account = profile.account
    # Use update_columns to prevent save callbacks that would send updates to Accounts
    account.update_columns(user_params.attributes.slice(ALLOWED_ATTRIBUTES))
  end
end
