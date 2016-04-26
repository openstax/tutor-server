class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  unique_token :teacher_join_token

  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity, dependent: :delete
  belongs_to :offering, subsystem: :catalog

  validates :course, presence: true, uniqueness: true
  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  before_save :timezone_updated, if: :timezone_changed?

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

  private

  def timezone_updated
    old_timezone, new_timezone = self.changes[:timezone]
    course.tasking_plans.map do |tp|
      tp.opens_at = change_timezone(tp.opens_at, old_timezone, new_timezone)
      tp.due_at = change_timezone(tp.due_at, old_timezone, new_timezone)
      tp.save
    end
  end

  def change_timezone(time, old_timezone, new_timezone)
    old_time = time.in_time_zone(old_timezone)
    new_time = time.in_time_zone(new_timezone)
    old_time.to_datetime.change(offset: new_time.formatted_offset)
  end
end
