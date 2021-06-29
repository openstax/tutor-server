class PaymentCode < IndestructibleRecord
  CONFUSED_CHARS = %w(B 8 G 6 I 1 O 0 S 5 Z 2)

  validates_presence_of :code
  validates_uniqueness_of :code

  before_validation :generate_code, on: :create
  after_rollback :regenerate_code

  before_update :preserve_persisted_code

  belongs_to :student, subsystem: :course_membership, inverse_of: :payment_codes, optional: true

  attr_accessor :prefix

  private

  def preserve_persisted_code
    throw :cannot_change_persisted_code if code_changed?
  end

  def code=(value)
    throw :cannot_change_persisted_code if persisted?
    super
  end

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
    return if persisted?
    save if errors.types[:code]&.include?(:taken)
  end
end
