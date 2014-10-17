class Student < ActiveRecord::Base
  belongs_to :user
  belongs_to :klass
  belongs_to :section
  has_one :course, through: :klass
  has_one :school, through: :course

  enum level: { graded: 0, auditing: 1 }
  
  validates :user, 
            presence: true

  validates :klass, 
            presence: true,
            uniqueness: { scope: :user_id }
  
  validates :section,
            uniqueness: { scope: :user_id, allow_nil: true }

  validates :random_education_identifier, 
            presence: true,
            uniqueness: true

  validate :section_is_in_klass

  validate :user_unchanged, on: :update

  before_validation :generate_random_education_identifier,
                    unless: :random_education_identifier

  protected

  def generate_random_education_identifier
    begin
      self.random_education_identifier = SecureRandom.hex(6)
    end while Student.where(random_education_identifier: random_education_identifier)
                     .exists?
  end

  def section_is_in_klass
    return if section.nil? || section.klass_id == klass_id
    errors.add(:section, 'does not agree with class')
    false
  end

  def user_unchanged
    return unless user.changed?
    errors.add(:user, 'cannot be changed after creation')
    false
  end

end
