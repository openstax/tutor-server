class Lms::Models::App < ApplicationRecord

  # Currently, apps are only owned by individual courses; later they will also
  # be owned by schools or school systems

  belongs_to :owner, polymorphic: true

  before_validation :initialize_tokens

  validates :owner, presence: true
  validates :owner_id, uniqueness: { scope: :owner_type }
  validates :key, presence: true, uniqueness: true

  scope :for_course, -> (course) { find_by(owner: course) }

  protected

  def initialize_tokens
    self.key ||= SecureRandom.hex(30)
    self.secret ||= SecureRandom.hex(30)
  end

end
