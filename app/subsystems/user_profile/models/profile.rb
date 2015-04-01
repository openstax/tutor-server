class UserProfile::Models::Profile < Tutor::SubSystems::BaseModel

  belongs_to :account, class_name: "OpenStax::Accounts::Account"
  belongs_to :entity_user, class_name: "::Entity::Models::User"
  has_many :groups_as_member, through: :account
  has_many :groups_as_owner, through: :account

  has_one :administrator, dependent: :destroy, inverse_of: :profile,
    class_name: 'UserProfile::Models::Administrator'

  validates :account, :entity_user, presence: true, uniqueness: true
  validates :exchange_identifier, presence: true

  delegate :username, :first_name, :last_name, :full_name, :title,
           :name, :casual_name, :first_name=, :last_name=, :full_name=,
           :title=, to: :account

  def self.anonymous
    UserProfile::Models::AnonymousUser.instance
  end

  def is_human?
    true
  end

  def is_application?
    false
  end

  def is_anonymous?
    false
  end

  def is_deleted?
    !deleted_at.nil?
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

  # So users can be treated like roles
  alias_method :user_id, :id
  def user; self; end

end
