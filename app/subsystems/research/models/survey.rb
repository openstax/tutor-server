class Research::Models::Survey < ApplicationRecord
  belongs_to :survey_plan
  belongs_to :student, subsystem: :course_membership

  validates :course, uniqueness: { scope: :research_study_id }

  def hidden?
    !permanently_hidden_at.nil?
  end

  def destroy
    false
  end
end
