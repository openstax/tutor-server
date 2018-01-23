class Research::Models::StudyCourse < ApplicationRecord
  belongs_to :study, inverse_of: :study_courses
  belongs_to :course, subsystem: :course_profile, inverse_of: :study_courses

  validates :study, presence: true
  validates :course, uniqueness: { scope: :research_study_id },
                     presence: true
end
