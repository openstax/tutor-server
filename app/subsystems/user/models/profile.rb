module User
  module Models
    class Profile < Tutor::SubSystems::BaseModel
      wrapped_by User::Strategies::Direct::User

      belongs_to :account, class_name: "OpenStax::Accounts::Account", subsystem: 'none'

      has_many :groups_as_member, through: :account, subsystem: 'none'
      has_many :groups_as_owner, through: :account, subsystem: 'none'

      has_many :role_users, subsystem: :role
      has_many :roles, through: :role_users

      has_one :administrator, dependent: :destroy, inverse_of: :profile
      has_one :content_analyst, dependent: :destroy, inverse_of: :profile

      validates :account, :user, presence: true, uniqueness: true
      validates :exchange_read_identifier, presence: true
      validates :exchange_write_identifier, presence: true

      delegate :username, :first_name, :last_name, :full_name, :title, :name, :casual_name,
               :first_name=, :last_name=, :full_name=, :title=, to: :account

      def self.anonymous
        User::Models::AnonymousProfile.instance
      end

      def destroy
        update_attribute(:deleted_at, Time.now)
      end

      def delete
        update_column(:deleted_at, Time.now)
      end

      def undelete
        update_column(:deleted_at, nil)
      end

    end
  end
end
