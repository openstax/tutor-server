class CourseProfile::Models::Course < Tutor::SubSystems::BaseModel

  include DefaultTimeValidations

  MIN_YEAR = 2015
  MAX_FUTURE_YEARS = 2

  belongs_to_time_zone default: 'Central Time (US & Canada)', dependent: :destroy, autosave: true

  belongs_to :cloned_from, foreign_key: 'cloned_from_id',
                           class_name: 'CourseProfile::Models::Course'

  belongs_to :school, subsystem: :school_district
  belongs_to :offering, subsystem: :catalog

  has_many :periods, subsystem: :course_membership, dependent: :destroy
  has_many :periods_with_deleted, -> { with_deleted }, subsystem: :course_membership,
           dependent: :destroy, class_name: 'CourseMembership::Models::Period'

  has_many :teachers, subsystem: :course_membership, dependent: :destroy
  has_many :students, subsystem: :course_membership, dependent: :destroy

  has_many :excluded_exercises, subsystem: :course_content, dependent: :destroy

  has_many :course_ecosystems, subsystem: :course_content, dependent: :destroy
  has_many :ecosystems, through: :course_ecosystems, subsystem: :content

  has_many :course_assistants, subsystem: :tasks, dependent: :destroy

  has_many :taskings, through: :periods, subsystem: :tasks

  has_many :cloned_courses, foreign_key: 'cloned_from_id',
                            class_name: 'CourseProfile::Models::Course'

  unique_token :teach_token

  enum term: [ :legacy, :demo, :spring, :summer, :fall ]

  validates :time_zone, presence: true, uniqueness: true
  validates :name, :term, :year, :starts_at, :ends_at,
            :biglearn_student_clues_algorithm_name,
            :biglearn_teacher_clues_algorithm_name,
            :biglearn_assignment_spes_algorithm_name,
            :biglearn_assignment_pes_algorithm_name,
            :biglearn_practice_worst_areas_algorithm_name,
            presence: true

  validate :default_times_have_good_values, :ends_after_it_starts, :valid_year

  delegate :name, to: :school, prefix: true, allow_nil: true

  before_validation :set_starts_at_and_ends_at

  scope :not_ended, -> { where{ends_at.gt Time.now} }

  def default_due_time
    read_attribute(:default_due_time) || Settings::Db.store[:default_due_time]
  end

  def default_open_time
    read_attribute(:default_open_time) || Settings::Db.store[:default_open_time]
  end

  def term_year
    return if term.nil? || year.nil?

    TermYear.new(term, year)
  end

  def num_sections
    periods.size
  end

  def started?(current_time = Time.current)
    starts_at <= current_time
  end

  def ended?(current_time = Time.current)
    ends_at < current_time
  end

  def active?(current_time = Time.current)
    started?(current_time) && !ended?(current_time)
  end

  def deletable?
    periods.empty? && teachers.empty? && students.empty?
  end

  protected

  def set_starts_at_and_ends_at
    return if starts_at.present? && ends_at.present?

    ty = term_year
    self.starts_at ||= ty.try!(:starts_at)
    self.ends_at   ||= ty.try!(:ends_at)
  end

  def ends_after_it_starts
    return if starts_at.nil? || ends_at.nil? || ends_at > starts_at
    errors.add :base, 'cannot end before it starts'
    false
  end

  def valid_year(current_year = Time.current.year)
    return if year.nil?
    valid_year_range = MIN_YEAR..current_year + MAX_FUTURE_YEARS
    return if valid_year_range.include?(year)
    errors.add :year, 'is outside the valid range'
    false
  end

end
