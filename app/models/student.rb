class Student < ActiveRecord::Base
  belongs_to :user, class_name: 'UserProfile::Models::Profile'
  belongs_to :course
  belongs_to :section

  has_many :tasking_plans, as: :target, dependent: :destroy
  has_many :taskings, as: :taskee, dependent: :destroy

  enum level: { graded: 0, auditing: 1 }

  validates :user,
            presence: true

  validates :course,
            presence: true,
            uniqueness: { scope: :user_id }

  validates :section,
            allow_nil: true,
            uniqueness: { scope: :user_id }

  validates :random_education_identifier,
            presence: true,
            uniqueness: true

  validate :section_is_in_course

  def section_is_in_course
    return if section.nil? || section.course_id == course_id
    errors.add(:section, 'does not agree with course')
    false
  end

end
