module User
  module Models
    class Profile < IndestructibleRecord
      belongs_to :account, class_name: 'OpenStax::Accounts::Account',
                           subsystem: 'none',
                           inverse_of: :profile

      has_many :roles, subsystem: :entity, dependent: :destroy, inverse_of: :profile

      has_many :enrollment_changes, subsystem: :course_membership
      has_many :tour_views, inverse_of: :profile
      has_many :tours, through: :tour_views

      has_one :administrator, dependent: :destroy, inverse_of: :profile
      has_one :customer_support, class_name: 'User::Models::CustomerService',
                                 dependent: :destroy, inverse_of: :profile
      has_one :content_analyst, dependent: :destroy, inverse_of: :profile
      has_one :researcher, dependent: :destroy, inverse_of: :profile

      json_serialize :ui_settings, Hash

      validates :account, uniqueness: true
      validates :ui_settings, max_json_length: 10_000

      delegate :username, :first_name, :last_name, :full_name, :title, :name, :casual_name, :role,
               :salesforce_contact_id, :faculty_status, :grant_tutor_access, :school_type,
               :school_location, :uuid, :support_identifier, :is_kip, :is_test,
               :first_name=, :last_name=, :full_name=, :title=, to: :account

      def self.anonymous
        ::User::Models::AnonymousProfile.instance
      end

      def can_create_courses?
        account.grant_tutor_access || (
          account.confirmed_faculty? && !account.foreign_school? && (
            account.college? || account.high_school? || account.home_school?
          )
        )
      end

      def is_human?
        true
      end

      def is_application?
        false
      end

      def is_signed_in?
        true
      end

      def is_anonymous?
        false
      end

      def is_admin?
        !administrator.nil?
      end

      def is_customer_support?
        !customer_support.nil?
      end

      def is_content_analyst?
        !content_analyst.nil?
      end

      def is_researcher?
        !researcher.nil?
      end

      def viewed_tour_stats
        tour_views.preload(:tour).map { |tv| { id: tv.tour.identifier, view_count: tv.view_count } }
      end
    end
  end
end
