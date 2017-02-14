module User
  module Models
    class Profile < Tutor::SubSystems::BaseModel

      acts_as_paranoid

      wrapped_by Strategies::Direct::User

      belongs_to :account, class_name: 'OpenStax::Accounts::Account', subsystem: 'none'

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

      attr_accessor :previous_ui_settings

      json_serialize :ui_settings, Hash

      validates :account, presence: true, uniqueness: true
      validates :ui_settings, max_json_length: 1500
      validate  :validate_ui_settings_change_history , on: :update

      delegate :username, :first_name, :last_name, :full_name, :title,
               :name, :casual_name, :salesforce_contact_id, :faculty_status,
               :first_name=, :last_name=, :full_name=, :title=, to: :account

      def self.anonymous
        ::User::Models::AnonymousProfile.instance
      end

      private

      def validate_ui_settings_change_history
        if ui_settings_changed? && previous_ui_settings != ui_settings_was
          errors.add(:previous_ui_settings,
                     'out-of-band update detected. Previous does not match stored value')
        end
      end

    end
  end
end
