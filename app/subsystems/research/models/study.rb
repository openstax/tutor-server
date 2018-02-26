class Research::Models::Study < IndestructibleRecord
  has_many :survey_plans, inverse_of: :study
  has_many :study_courses, inverse_of: :study
  has_many :courses, through: :study_courses, subsystem: :course_profile, inverse_of: :studies
  has_many :cohorts, inverse_of: :study

  validates :name, presence: true

  def active?
    raise "nyi"
  end

  # TODO don't allow activate_at to be changed when active
end
