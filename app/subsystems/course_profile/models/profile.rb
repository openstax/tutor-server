class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  unique_token :teacher_join_token

  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity

  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.collect(&:name) }

  delegate :name, to: :school,
                  prefix: true,
                  allow_nil: true
end
