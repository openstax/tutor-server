class User < ActiveRecord::Base

  belongs_to :account, class_name: "OpenStax::Accounts::Account"
  has_many :groups_as_member, through: :account
  has_many :groups_as_owner, through: :account

  has_one :administrator, dependent: :destroy, inverse_of: :user

  has_many :course_managers, dependent: :destroy
  has_many :school_managers, dependent: :destroy
  has_many :educators, dependent: :destroy
  has_many :students, dependent: :destroy

  validates :account, presence: true, uniqueness: true
  validates :exchange_identifier, presence: true

  delegate :username, :first_name, :last_name, :full_name, :title,
           :name, :casual_name, :first_name=, :last_name=, :full_name=,
           :title=, to: :account

  def self.anonymous
    AnonymousUser.instance
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
  # Dante: not a huge fan of this... is it REALLY needed?
  alias_method :user_id, :id
  def user; self; end

end
