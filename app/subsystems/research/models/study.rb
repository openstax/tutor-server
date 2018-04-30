class Research::Models::Study < ApplicationRecord
  has_many :survey_plans, inverse_of: :study, dependent: :destroy
  has_many :study_courses, inverse_of: :study, dependent: :destroy
  has_many :courses, through: :study_courses, subsystem: :course_profile, inverse_of: :studies
  has_many :cohorts, inverse_of: :study, dependent: :destroy

  validates :name, presence: true

  validate :activate_at_not_cleared, on: :update
  validate :activate_at_not_changed_when_active, on: :update

  before_destroy :only_destroy_if_active

  def active?
    activate_at.present? && activate_at < Time.current
  end

  protected

  def activate_at_not_cleared
    errors.add(:activate_at, " cannot be cleared after being set") if activate_at_changed? && activate_at.nil?
    errors.none?
  end

  def activate_at_not_changed_when_active
    errors.add(:activate_at, " cannot be cleared after being set") if activate_at_changed? && active?
    errors.none?
  end

  def only_destroy_if_active
    errors.add(:base, "Cannot destroy an active study") if active?
    errors.none?
  end
end
