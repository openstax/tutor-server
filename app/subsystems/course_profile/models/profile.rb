class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity
  belongs_to :school, class_name: 'CourseDetail::Models::School', foreign_key: :course_detail_school_id

  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.collect(&:name) }

  delegate :name, to: :school,
                  prefix: true,
                  allow_nil: true
end
