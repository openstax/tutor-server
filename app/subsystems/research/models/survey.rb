class Research::Models::Survey < ApplicationRecord
  belongs_to :survey_plan, subsystem: :research
  belongs_to :student, subsystem: :course_membership

  validates :student, uniqueness: { scope: :research_survey_plan_id }

  def is_hidden?
    !permanently_hidden_at.nil?
  end

  def destroy
    false
  end
end
