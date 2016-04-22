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

  def default_due_time
    default = Time.parse(Settings::Db.store[:course_default_due_time]) rescue Time.parse('00:00')
    attr = read_attribute(:default_due_time)
    attr.nil? ? default : attr
  end

  def default_open_time
    default = Time.parse(Settings::Db.store[:course_default_open_time]) rescue Time.parse('00:00')
    attr = read_attribute(:default_open_time)
    attr.nil? ? default : attr
  end
end
