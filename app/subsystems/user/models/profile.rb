module User
  module Models
    class Profile < Tutor::SubSystems::BaseModel

      acts_as_paranoid

      wrapped_by Strategies::Direct::User

      belongs_to :account,
                 class_name: 'OpenStax::Accounts::Account',
                 subsystem: 'none',
                 inverse_of: :profile

      has_many :groups_as_member, through: :account, subsystem: 'none'
      has_many :groups_as_owner, through: :account, subsystem: 'none'

      has_many :role_users, subsystem: :role
      has_many :roles, through: :role_users, subsystem: :entity

      has_many :enrollment_changes, subsystem: :course_membership
      has_many :tour_views, inverse_of: :profile
      has_many :tours, through: :tour_views

      has_one :administrator, dependent: :destroy, inverse_of: :profile
      has_one :customer_service, dependent: :destroy, inverse_of: :profile
      has_one :content_analyst, dependent: :destroy, inverse_of: :profile

      json_serialize :ui_settings, Hash

      validates :account, presence: true, uniqueness: true
      validates :ui_settings, max_json_length: 10_000

      delegate :username, :first_name, :last_name, :full_name, :title, :uuid,
               :name, :casual_name, :salesforce_contact_id, :faculty_status, :role,
               :first_name=, :last_name=, :full_name=, :title=, to: :account

      def self.anonymous
        ::User::Models::AnonymousProfile.instance
      end

    end
  end
end

# Leave this monkey patch of Account here.  If moved to a location that is
# not reloaded by Rails, things break in the development environment.
OpenStax::Accounts::Account.class_exec do
  has_one :profile, primary_key: :id,
                    foreign_key: :account_id,
                    class_name: 'User::Models::Profile',
                    inverse_of: :account
end
