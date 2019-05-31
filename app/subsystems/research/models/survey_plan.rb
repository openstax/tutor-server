class Research::Models::SurveyPlan < ApplicationRecord
  belongs_to :study, inverse_of: :survey_plans
  has_many :surveys, inverse_of: :survey_plan

  validates :title_for_researchers, presence: true
  validates :title_for_students, presence: true
  validate :changes_allowed

  scope :published, -> { where.not(published_at: nil) }
  scope :not_hidden, -> { where(hidden_at: nil) }

  def destroy
    false
  end

  def is_published?
    !published_at.nil?
  end

  def is_hidden?
    !hidden_at.nil?
  end

  def changes_allowed
    return unless is_published? && survey_js_model_changed?

    errors.add(:survey_js_model, "cannot be changed after publication")
    throw :abort
  end
end
