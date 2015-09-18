class Admin::UsersCreate
  lev_handler

  uses_routine UserProfile::CreateProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_profile

  ALLOWED_ATTRIBUTES = ['username', 'password', 'first_name', 'last_name',
                        'full_name', 'title', 'email']

  paramify :user do
    attribute :username, type: String
    attribute :password, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :email, type: String

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
    run(:create_profile, **user_params.attributes.slice(ALLOWED_ATTRIBUTES).symbolize_keys)
  end
end
