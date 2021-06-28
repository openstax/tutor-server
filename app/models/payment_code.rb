class PaymentCode < ApplicationRecord
  CONFUSED_CHARS = %w(B 8 G 6 I 1 O 0 S 5 Z 2)

  validates_presence_of :code
  validates_uniqueness_of :code

  before_validation :generate_code, on: :create
  after_rollback :regenerate_code

  belongs_to :student, subsystem: :course_membership, inverse_of: :payment_codes, optional: true

  attr_accessor :prefix

  def generate_code
    unless prefix.present?
      errors.add :prefix, :blank
      throw :abort
    end

    base = [*'0'..'9', *'A'..'Z'] - CONFUSED_CHARS
    post = Array.new(10) { base.sample }.join
    self.code = "#{prefix.parameterize.upcase}-#{post}"
  end

  def regenerate_code
    if errors.types[:code]&.include?(:taken)
      generate_code
      save
    end
  end
end
