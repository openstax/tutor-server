class Role::Models::RoleUser < Tutor::SubSystems::BaseModel
  belongs_to :profile, subsystem: :user
  belongs_to :role, subsystem: :entity

  validates :profile, presence: true
  validates :role, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :profile

  # Hack to be used until the Role subsystem has its own wrappers
  def user
    strategy = ::User::Strategies::Direct::Profile.new(profile)
    ::User::User.new(strategy: strategy)
  end
end
