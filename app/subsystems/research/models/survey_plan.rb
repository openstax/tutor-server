class Research::Models::SurveyPlan < ApplicationRecord
  belongs_to :study

  validates :title, presence: true
  validate :changes_allowed

  def destroy
    false
  end

  def published?
    !published_at.nil?
  end

  def hidden?
    !permanently_hidden_at.nil?
  end

  def changes_allowed
    errors.add(:survey_js_model, "cannot be changed after publication") \
      if survey_js_model_changed? && published?

    errors.any?
  end
end
