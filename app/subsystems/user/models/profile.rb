module User
  module Models
    class Profile < IndestructibleRecord

      wrapped_by Strategies::Direct::User

      belongs_to :account, class_name: 'OpenStax::Accounts::Account',
                           subsystem: 'none',
                           inverse_of: :profile

      has_many :groups_as_member, through: :account, subsystem: 'none'
      has_many :groups_as_owner, through: :account, subsystem: 'none'

      has_many :roles, subsystem: :entity, dependent: :destroy, inverse_of: :profile

      has_many :enrollment_changes, subsystem: :course_membership
      has_many :tour_views, inverse_of: :profile
      has_many :tours, through: :tour_views

      has_one :administrator, dependent: :destroy, inverse_of: :profile
      has_one :customer_service, dependent: :destroy, inverse_of: :profile
      has_one :content_analyst, dependent: :destroy, inverse_of: :profile
      has_one :researcher, dependent: :destroy, inverse_of: :profile

      json_serialize :ui_settings, Hash

      validates :account, uniqueness: true
      validates :ui_settings, max_json_length: 10_000

      delegate :username, :first_name, :last_name, :full_name, :title, :name, :casual_name,
               :salesforce_contact_id, :faculty_status, :role, :school_type, :uuid,
               :support_identifier, :is_test, :first_name=, :last_name=, :full_name=, :title=,
               to: :account

      def self.anonymous
        ::User::Models::AnonymousProfile.instance
      end

    end
  end
end
