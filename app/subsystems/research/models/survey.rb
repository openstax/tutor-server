class Research::Models::Survey < ApplicationRecord
  belongs_to :survey_plan, subsystem: :research
  belongs_to :student, subsystem: :course_membership

  validates :student, uniqueness: { scope: :research_survey_plan_id }
  validate :ensure_no_response_while_hidden

  def is_hidden?
    !hidden_at.nil?
  end

  def destroy
    false
  end

  protected

  def ensure_no_response_while_hidden
    if is_hidden? && survey_js_response_changed?
      errors.add(:survey_js_response_changed, 'cannot be updated when survey is hidden')
    end
  end

end
