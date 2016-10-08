class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  include DefaultTimeValidations

  belongs_to_time_zone default: 'Central Time (US & Canada)', dependent: :destroy, autosave: true

  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity, dependent: :delete
  belongs_to :offering, subsystem: :catalog

  unique_token :teach_token

  validates :course, :time_zone, presence: true, uniqueness: true
  validates :name, :starts_at, :ends_at, presence: true

  validate :default_times_have_good_values, :ends_after_it_starts

  delegate :name, to: :school, prefix: true, allow_nil: true

  def default_due_time
    read_attribute(:default_due_time) || Settings::Db.store[:default_due_time]
  end

  def default_open_time
    read_attribute(:default_open_time) || Settings::Db.store[:default_open_time]
  end

  def active?(current_time = Time.current)
    starts_at <= current_time && current_time <= ends_at
  end

  protected

  def ends_after_it_starts
    return if starts_at.nil? || ends_at.nil? || ends_at > starts_at
    errors.add :base, 'cannot end before it starts'
    false
  end
end
