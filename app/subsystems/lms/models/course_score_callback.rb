class Lms::Models::CourseScoreCallback < ApplicationRecord
  # Records data needed to post a course score for a student back to an LMS.
  # Though not intended, a student could have multiple of these if a teacher
  # adds more than one Tutor assignment in their LMS.  Since we just report
  # course scores all such assignments would get the same score; but we can
  # at least deal with this situation until the teacher realizes that is not
  # useful.

  belongs_to :course, subsystem: :course_profile
  belongs_to :profile, subsystem: :user

  validates :outcome_url, presence: true
  validates :result_sourcedid, presence: true, uniqueness: { scope: :outcome_url }
end
