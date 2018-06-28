class Research::Models::Study < ApplicationRecord
  has_many :survey_plans, inverse_of: :study, dependent: :destroy
  has_many :study_courses, inverse_of: :study, dependent: :destroy
  has_many :courses, through: :study_courses, subsystem: :course_profile, inverse_of: :studies
  has_many :cohorts, inverse_of: :study, dependent: :destroy

  validates :name, presence: true

  before_destroy :only_destroy_if_inactive

  scope :never_active, -> { where(last_activated_at: nil) }

  scope :activate_at_has_passed, -> {
    where.not(activate_at: nil).
    where("activate_at < ?", Time.current)
  }

  scope :active, -> {
    where.not(last_activated_at: nil).
    where("last_deactivated_at IS NULL OR last_deactivated_at < last_activated_at")
  }

  scope :deactivate_at_has_passed, -> {
    where.not(deactivate_at: nil).
    where("deactivate_at < ?", Time.current)
  }

  def active?
    last_activated_at.present? && (
      last_deactivated_at.nil? ||
      last_activated_at > last_deactivated_at
    )
  end

  def ever_active?
    last_activated_at.present?
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

  def only_destroy_if_inactive
    errors.add(:base, "Cannot destroy an active study") if active?
    errors.none?
  end
end
