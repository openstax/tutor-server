class Research::Models::Study < IndestructibleRecord
  has_many :survey_plans, inverse_of: :study
  has_many :study_courses, inverse_of: :study
  has_many :courses, through: :study_courses, subsystem: :course_profile, inverse_of: :studies

  validates :name, presence: true
end
