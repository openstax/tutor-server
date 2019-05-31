class Research::Models::Survey < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  belongs_to :survey_plan, subsystem: :research, inverse_of: :surveys
  belongs_to :student, subsystem: :course_membership, inverse_of: :surveys

  validates :student, uniqueness: { scope: :research_survey_plan_id }
  validate :ensure_no_response_while_hidden

  def is_hidden?
    !hidden_at.nil?
  end

  protected

  def ensure_no_response_while_hidden
    return unless is_hidden? && survey_js_response_changed?

    errors.add(:survey_js_response, 'cannot be updated when survey is hidden')
    throw :abort
  end
end
