class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  include DefaultTimeValidations

  belongs_to_time_zone default: 'Central Time (US & Canada)', dependent: :destroy, autosave: true


  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity, dependent: :delete
  belongs_to :offering, subsystem: :catalog

  unique_token :teach_token

  validates :course, :time_zone, presence: true, uniqueness: true
  validates :name, presence: true

  validate :default_times_have_good_values

  delegate :name, to: :school, prefix: true, allow_nil: true

  def default_due_time
    read_attribute(:default_due_time) || Settings::Db.store[:default_due_time]
  end

  def default_open_time
    read_attribute(:default_open_time) || Settings::Db.store[:default_open_time]
  end
end
