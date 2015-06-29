class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity

  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.collect{ |tz| tz.name } }
end
