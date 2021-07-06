class PaymentCode < IndestructibleRecord
  CONFUSED_CHARS = %w(B 8 G 6 I 1 O 0 S 5 Z 2)

  validates_presence_of :code
  validates_uniqueness_of :code

  before_validation :set_code, on: :create
  after_rollback :handle_collision

  before_update :preserve_persisted_code

  belongs_to :student, subsystem: :course_membership, inverse_of: :payment_codes, optional: true

  attr_accessor :prefix

  private

  def preserve_persisted_code
    throw_persisted_error if code_changed?
  end

  def code=(value)
    throw_persisted_error if persisted?
    super
  end

  def generate_code
    unless prefix.present?
      errors.add :prefix, :blank
      raise ActiveRecord::RecordInvalid
    end

    base = [*'0'..'9', *'A'..'Z'] - CONFUSED_CHARS
    post = Array.new(10) { base.sample }.join
    "#{prefix.parameterize.upcase}-#{post}"
  end

  def set_code
    throw_persisted_error if persisted?
    self.code = generate_code
  end

  def handle_collision
    if errors.types[:code]&.include?(:taken)
      set_code
      save
    end
  end

  def throw_persisted_error
    throw :cannot_change_persisted_code
  end
end
