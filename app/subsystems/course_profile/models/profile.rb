class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  unique_token :teacher_join_token

  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity, dependent: :delete
  belongs_to :offering, subsystem: :catalog

  validates :course, presence: true, uniqueness: true
  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  include DefaultTimeValidations
  validate :default_times_have_good_values

  delegate :name, to: :school,
                  prefix: true,
                  allow_nil: true

  def default_due_time
    read_attribute(:default_due_time) || Settings::Db.store[:course_default_due_time]
  end

  def default_open_time
    read_attribute(:default_open_time) || Settings::Db.store[:course_default_open_time]
  end

end
