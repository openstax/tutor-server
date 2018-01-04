class Research::Models::SurveyPlan < ApplicationRecord
  belongs_to :study

  validates :title_for_researchers, presence: true
  validates :title_for_students, presence: true
  validate :changes_allowed

  def destroy
    false
  end

  def is_published?
    !published_at.nil?
  end

  def is_hidden?
    !permanently_hidden_at.nil?
  end

  def changes_allowed
    errors.add(:survey_js_model, "cannot be changed after publication") \
      if survey_js_model_changed? && is_published?

    errors.any?
  end
end
