class Lms::Models::CourseGradeCallback < Tutor::SubSystems::BaseModel
  belongs_to :student, subsystem: :course_membership

  validates :outcome_url, presence: true
  validates :result_sourcedid, presence: true, uniqueness: { scope: :outcome_url }
end
