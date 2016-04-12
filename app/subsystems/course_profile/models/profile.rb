class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  unique_token :teacher_join_token

  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity, dependent: :delete
  belongs_to :offering, subsystem: :catalog

  validates :course, presence: true, uniqueness: true
  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  delegate :name, to: :school,
                  prefix: true,
                  allow_nil: true
end
