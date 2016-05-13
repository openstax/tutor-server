class CourseProfile::Models::TimeZone < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :course_profile
  has_many :tasking_plans, subsystem: :tasks
  has_many :tasks, subsystem: :tasks

  validates :name, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  def to_tz
    ActiveSupport::TimeZone[name]
  end
end
