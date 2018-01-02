class Research::Models::StudyCourse < ApplicationRecord
  belongs_to :study
  belongs_to :course, subsystem: :course_profile

  validates :course, uniqueness: { scope: :research_study_id }
end
