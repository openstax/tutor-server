class Lms::Models::App < ApplicationRecord

  # Currently, apps are only owned by individual courses; later they will also
  # be owned by schools or school systems

  belongs_to :owner, polymorphic: true

  before_validation :initialize_tokens

  validates :owner, presence: true
  validates :owner_id, uniqueness: { scope: :owner_type }
  validates :key, presence: true, uniqueness: true


  def self.supports_key?(key)
    find_by(key: request_parameters[:oauth_consumer_key])
  end

  protected

  def initialize_tokens
    self.key ||= SecureRandom.hex(30)
    self.secret ||= SecureRandom.hex(30)
  end

end
