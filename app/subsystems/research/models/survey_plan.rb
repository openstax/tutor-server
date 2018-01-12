class Research::Models::SurveyPlan < ApplicationRecord
  belongs_to :study
  has_many :surveys

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
    errors.add(:survey_js_model, "cannot be changed after publication") \
      if survey_js_model_changed? && is_published?

    errors.any?
  end
end
