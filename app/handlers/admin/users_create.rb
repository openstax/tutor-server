class Admin::UsersCreate
  ALLOWED_ATTRIBUTES = ['username', 'password', 'first_name', 'last_name',
                        'full_name', 'title', 'email']

  lev_handler

  uses_routine UserProfile::CreateProfile, translations: { outputs: { type: :verbatim } },
                                           as: :create_profile
  uses_routine UserProfile::Routines::SetAdministratorState, as: :set_administrator
  uses_routine UserProfile::Routines::SetContentAnalystState, as: :set_content_analyst

  paramify :user do
    attribute :username, type: String
    attribute :password, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :email, type: String
    attribute :administrator, type: boolean
    attribute :content_analyst, type: boolean

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
    run(:create_profile, **user_params.attributes.slice(*ALLOWED_ATTRIBUTES).symbolize_keys)

    profile = outputs[:profile]
    run(:set_administrator, profile: profile, administrator: user_params.administrator)
    run(:set_content_analyst, profile: profile, content_analyst: user_params.content_analyst)
  end
end
