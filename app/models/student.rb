class Student < ActiveRecord::Base
  belongs_to :user
  belongs_to :klass
  belongs_to :section

  has_many :tasking_plans, as: :target, dependent: :destroy
  has_many :taskings, as: :taskee, dependent: :destroy

  enum level: { graded: 0, auditing: 1 }
  
  validates :user, 
            presence: true

  validates :klass, 
            presence: true,
            uniqueness: { scope: :user_id }
  
  validates :section, 
            allow_nil: true,
            uniqueness: { scope: :user_id }

  validates :random_education_identifier, 
            presence: true,
            uniqueness: true

  validate :section_is_in_klass

  def section_is_in_klass
    return if section.nil? || section.klass_id == klass_id
    errors.add(:section, 'does not agree with class')
    false
  end

end
