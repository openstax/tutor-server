class CourseProfile::Models::Course < ApplicationRecord
  MIN_YEAR = 2015
  MAX_FUTURE_YEARS = 2
  VALID_TIMEZONES = [
    'US/Central',
    'US/Pacific',
    'US/Eastern',
    'US/Mountain',
    'US/Arizona',
    'US/Hawaii',
    'US/Alaska',
    'US/East-Indiana',
    'Canada/Atlantic'
  ]

  acts_as_paranoid without_default_scope: true

  belongs_to :cloned_from, foreign_key: 'cloned_from_id',
                           class_name: 'CourseProfile::Models::Course',
                           optional: true

  belongs_to :school, subsystem: :school_district, optional: true

  belongs_to :offering, subsystem: :catalog, optional: true

  # These associations do not have dependent: :destroy because the course is soft-deleted
  has_many :lms_contexts, subsystem: :lms, class_name: 'Lms::Models::Context'
  has_many :periods, subsystem: :course_membership, inverse_of: :course

  has_many :teachers, subsystem: :course_membership, inverse_of: :course
  has_many :students, subsystem: :course_membership, inverse_of: :course
  has_many :teacher_students, subsystem: :course_membership, inverse_of: :course

  has_many :excluded_exercises, subsystem: :course_content

  has_many :course_ecosystems, subsystem: :course_content

  has_many :course_assistants, subsystem: :tasks

  has_many :task_plans, subsystem: :tasks, inverse_of: :course

  has_many :tasks, subsystem: :tasks, inverse_of: :course

  has_many :taskings, through: :periods, subsystem: :tasks

  has_many :cloned_courses, foreign_key: 'cloned_from_id',
                            class_name: 'CourseProfile::Models::Course'

  has_many :study_courses, subsystem: :research, inverse_of: :course
  has_many :studies, through: :study_courses, subsystem: :research, inverse_of: :courses

  has_many :grading_templates, subsystem: :tasks, inverse_of: :course

  unique_token :teach_token

  enum term: [ :legacy, :demo, :spring, :summer, :fall, :winter, :preview ]

  validates :timezone, presence: true, inclusion: { in: VALID_TIMEZONES }
  validates :name, :term, :year, :starts_at, :ends_at, presence: true
  validates :homework_weight,
            :reading_weight,
            presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  validate :ends_after_it_starts, :valid_year

  validate :lms_enabling_changeable, :weights_add_up

  delegate :name, to: :school, prefix: true, allow_nil: true

  before_validation :set_starts_at_and_ends_at, :set_weights

  scope :not_ended, -> { where(arel_table[:ends_at].gt(Time.now)) }

  # Reads the timezone attribute as an ActiveSupport::TimeZone, defaulting to US/Central
  def time_zone
    ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['US/Central']
  end

  def ecosystems
    # Keep the ecosystems in order
    course_ecosystems.to_a.tap do |course_ecosystems|
      ActiveRecord::Associations::Preloader.new.preload(course_ecosystems, :ecosystem)
    end.map(&:ecosystem)
  end

  def ecosystem
    # Slightly more efficient than .ecosystems.first
    course_ecosystems.first&.ecosystem
  end

  def initial_ecosystem_id
    course_ecosystems.last&.content_ecosystem_id
  end

  def current_ecosystem_id
    course_ecosystems.first&.content_ecosystem_id
  end

  def should_reuse_preview?
    return unless is_preview

    current_ecosystem_id == initial_ecosystem_id &&
    current_ecosystem_id == offering&.content_ecosystem_id
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
    periods.all?(&:archived?) && teachers.all?(&:deleted?) && students.all?(&:dropped?)
  end

  def spy_info
    { research_studies: studies.pluck(:name) }
  end

  def pre_wrm_scores?
    !is_preview && ended?(DateTime.new(2020, 7))
  end

  def frozen_scores?(current_time = Time.current)
    ended?(current_time) && !teacher_performance_report.nil?
  end

  protected

  def set_starts_at_and_ends_at
    return if starts_at.present? && ends_at.present?

    ty = term_year
    self.starts_at ||= ty&.starts_at
    self.ends_at   ||= ty&.ends_at
  end

  def set_weights
    self.homework_weight ||= 0.5
    self.reading_weight ||= 1 - homework_weight
  end

  def ends_after_it_starts
    return if starts_at.nil? || ends_at.nil? || ends_at > starts_at

    errors.add :base, 'cannot end before it starts'
    throw :abort
  end

  def valid_year(current_year = Time.current.year)
    return if year.nil?
    valid_year_range = MIN_YEAR..current_year + MAX_FUTURE_YEARS
    return if valid_year_range.include?(year)

    errors.add :year, 'is outside the valid range'
    throw :abort
  end

  def lms_enabling_changeable
    return unless is_lms_enabled_changed?

    errors.add(:is_lms_enabled, "Enabling LMS integration is not allowed for this course") \
      if is_lms_enabled && !is_lms_enabling_allowed

    errors.add(
      :is_lms_enabled, "Enabling or disabling LMS integration is not allowed for this course"
    ) unless is_access_switchable

    throw(:abort) if errors.any?
  end

  def weights_add_up
    return if [ homework_weight, reading_weight ].sum == 1

    errors.add(:base, 'weights must add up to exactly 1')
    throw :abort
  end
end
