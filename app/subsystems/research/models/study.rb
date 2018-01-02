class Research::Models::Study < ApplicationRecord
  has_many :survey_plans
  has_many :study_courses
  has_many :courses, through: :study_courses, subsystem: :course_profile

  validates :name, presence: true
end
