require 'json-schema'

class Tasks::Models::TaskPlan < ApplicationRecord
  acts_as_paranoid column: :withdrawn_at, without_default_scope: true

  UPDATEABLE_ATTRIBUTES_AFTER_OPEN = [
    'title',
    'description',
    'last_published_at',
    'tasks_grading_template_id',
    'gradable_step_count',
    'ungraded_step_count'
  ]

  CACHE_COLUMNS = [
    :gradable_step_count,
    :ungraded_step_count
  ]

  attr_accessor :is_publish_requested

  # Allow use of 'type' column without STI
  self.inheritance_column = nil

  belongs_to :cloned_from, foreign_key: 'cloned_from_id',
                           class_name: 'Tasks::Models::TaskPlan',
                           optional: true

  belongs_to :assistant
  belongs_to :course, subsystem: :course_profile, inverse_of: :task_plans
  belongs_to :ecosystem, subsystem: :content
  belongs_to :grading_template, optional: true, inverse_of: :task_plans

  # These associations do not have dependent: :destroy because the task_plan is soft-deleted
  has_many :tasking_plans, inverse_of: :task_plan
  has_many :tasks, inverse_of: :task_plan
  has_many :extensions, inverse_of: :task_plan
  has_many :dropped_questions, inverse_of: :task_plan

  delegate :timezone, :time_zone, to: :course

  json_serialize :settings, Hash

  before_validation :trim_text, :set_and_return_ecosystem, :set_wrq_count

  validates :title, presence: true
  validates :type, presence: true
  validates :tasking_plans, presence: true

  validate :valid_settings,
           :valid_ecosystem,
           :ecosystem_matches,
           :changes_allowed,
           :settings_valid_for_publishing,
           :not_past_due_when_publishing,
           :has_grading_template_if_gradable,
           :grading_template_same_course,
           :grading_template_type_matches,
           :correct_num_points_for_homework

  scope :tasked_to_period_id, ->(period_id) do
    joins(:tasking_plans).where(
      tasking_plans: { target_id: period_id, target_type: 'CourseMembership::Models::Period' }
    )
  end

  scope :published,     -> { where.not first_published_at: nil }
  scope :non_withdrawn, -> { where withdrawn_at: nil }

  scope :preload_tasking_plans, -> { preload(:tasking_plans, :course) }

  scope :preload_tasks, -> { preload(tasks: :course) }

  def reload(*args)
    @available_points_without_dropping_per_question_index = nil
    @unarchived_period_tasking_plans = nil

    super
  end

  def withdrawn?
    deleted?
  end

  def out_to_students?(current_time: Time.current)
    tasks.select(&:student?).any? { |task| task.past_open?(current_time: current_time) }
  end

  def is_draft?
    !is_publishing? && !is_published?
  end

  def is_publishing?
    publish_last_requested_at.present? &&
      (last_published_at.blank? || publish_last_requested_at > last_published_at)
  end

  def is_published?
    first_published_at.present? || last_published_at.present?
  end

  def publish_job
    Jobba.find(publish_job_uuid) if publish_job_uuid.present?
  end

  def num_completed_tasks
    tasks.to_a.count { |task| task.completed? use_cache: true }
  end

  def num_in_progress_tasks
    tasks.to_a.count { |task| task.in_progress? use_cache: true }
  end

  def num_not_started_tasks
    tasks.to_a.count { |task| !task.started? use_cache: true }
  end

  def reading?
    type == 'reading'
  end

  def homework?
    type == 'homework'
  end

  def gradable?
    homework? || reading?
  end

  # NOTE: This method does not know the final number of questions assigned
  #       Look at methods in the Task model for that
  def available_points_without_dropping_per_question_index
    @available_points_without_dropping_per_question_index ||= Hash.new(1.0).tap do |hash|
      if homework?
        question_index = 0
        settings['exercises'].each do |exercise|
          exercise['points'].each do |points|
            hash[question_index] = points
            question_index += 1
          end
        end
      end
    end
  end

  def late_work_penalty
    grading_template&.late_work_penalty || 0.0
  end

  def set_and_return_ecosystem
    self.ecosystem ||= cloned_from&.ecosystem ||
                       get_ecosystems_from_settings&.first ||
                       course&.ecosystems&.first
  end

  def unarchived_period_tasking_plans
    return @unarchived_period_tasking_plans unless @unarchived_period_tasking_plans.nil?

    period_tasking_plans = tasking_plans.filter do |tasking_plan|
      tasking_plan.target_type == 'CourseMembership::Models::Period'
    end
    ActiveRecord::Associations::Preloader.new.preload period_tasking_plans, :target

    @unarchived_period_tasking_plans = period_tasking_plans.reject do |tasking_plan|
      tasking_plan.target.archived?
    end
  end

  def update_gradable_step_counts
    period_ids = unarchived_period_tasking_plans.map(&:target_id)
    st = CourseMembership::Models::Student.arel_table
    tasks_by_period_id = tasks
      .select(:gradable_step_count, :ungraded_step_count, st[:course_membership_period_id])
      .joins(taskings: { role: { student: :period } })
      .where(
        taskings: {
          role: { student: { dropped_at: nil, course_membership_period_id: period_ids } }
        }
      )
      .group_by(&:course_membership_period_id)

    unarchived_period_tasking_plans.each do |tasking_plan|
      tasks = tasks_by_period_id[tasking_plan.target_id] || []

      tasking_plan.gradable_step_count = tasks.sum(&:gradable_step_count)
      tasking_plan.ungraded_step_count = tasks.sum(&:ungraded_step_count)
    end

    self.gradable_step_count = unarchived_period_tasking_plans.sum(&:gradable_step_count)
    self.ungraded_step_count = unarchived_period_tasking_plans.sum(&:ungraded_step_count)

    self
  end

  def update_gradable_step_counts!
    update_gradable_step_counts

    unarchived_period_tasking_plans.each { |tasking_plan| tasking_plan.save validate: false }

    save validate: false
  end

  def number_of_wrq_steps
    Content::Models::Exercise
      .select(:question_answer_ids)
      .where(id: exercise_ids)
      .filter(&:is_free_response_only?)
      .size
  end

  def core_page_ids
    settings['page_ids'] || []
  end

  protected

  def set_wrq_count
    self.wrq_count = number_of_wrq_steps
  end

  def get_ecosystems_from_exercise_ids
    ecosystems = Content::Models::Ecosystem.distinct.joins(:exercises).where(
      exercises: { id: exercise_ids }
    ).to_a
  end

  def get_ecosystems_from_page_ids
    ecosystems = Content::Models::Ecosystem.distinct.joins(:pages).where(
      pages: { id: core_page_ids }
    ).to_a
  end

  def get_ecosystems_from_settings
    if settings['exercises'].present?
      get_ecosystems_from_exercise_ids
    elsif core_page_ids.present?
      get_ecosystems_from_page_ids
    end
  end

  def valid_settings
    schema = assistant.try(:schema)
    return if schema.blank?

    json_errors = JSON::Validator.fully_validate(schema, settings, insert_defaults: true)
    return if json_errors.empty?

    json_errors.each { |json_error| errors.add(:settings, "- #{json_error}") }
    throw :abort
  end

  def valid_ecosystem
    return if course.nil? || course.ecosystems.include?(ecosystem)

    errors.add(:ecosystem, 'is not valid for this course')
    throw :abort
  end

  def ecosystem_matches
    return if ecosystem.nil?

    # Special checks for the page_ids and exercises settings
    errors.add(
      :settings,
      "- Some of the given exercise IDs do not belong to the ecosystem with ID #{ecosystem.id}"
    ) if settings['exercises'].present? && get_ecosystems_from_exercise_ids != [ ecosystem ]

    errors.add(
      :settings,
      "- Some of the given page IDs do not belong to the ecosystem with ID #{ecosystem.id}"
    ) if core_page_ids.present? && get_ecosystems_from_page_ids != [ ecosystem ]

    throw(:abort) if errors.any?
  end

  def has_grading_template_if_gradable
    return unless gradable? && grading_template.nil?

    errors.add :grading_template, 'must be present for readings and homeworks'
    throw :abort
  end

  def grading_template_same_course
    return if grading_template.nil? || grading_template.course == course

    errors.add :grading_template, 'must belong to the same course'
    throw :abort
  end

  def grading_template_type_matches
    return if grading_template.nil? || grading_template.task_plan_type == type

    errors.add :grading_template, 'is for a different task_plan type'
    throw :abort
  end

  def changes_allowed
    return unless out_to_students?

    forbidden_attributes = changes.except(*UPDATEABLE_ATTRIBUTES_AFTER_OPEN)
    return if forbidden_attributes.empty?

    forbidden_attributes.each { |key, value| errors.add key.to_sym, 'cannot be updated after open' }

    throw :abort
  end

  def settings_valid_for_publishing
    return unless is_publish_requested
    errors.add(:settings, 'must have at least one exercise') if homework? && settings['exercises'].blank?
    errors.add(:settings, 'must have at least one page') if reading? && core_page_ids.blank?
  end

  def not_past_due_when_publishing
    return if is_published? || !is_publish_requested || tasking_plans.none?(&:past_due?)

    errors.add :due_at, 'cannot be in the past when publishing'
    throw :abort
  end

  def exercise_ids
    settings['exercises']&.map { |ex| ex['id'] } || []
  end

  def correct_num_points_for_homework
    return if type != 'homework' || settings.blank? || settings['exercises'].blank?

    num_questions_by_exercise_id = {}
    Content::Models::Exercise.select(:id, :number_of_questions)
                             .where(id: exercise_ids)
                             .each do |exercise|
      num_questions_by_exercise_id[exercise.id.to_s] = exercise.number_of_questions
    end

    settings['exercises'].each do |exercise|
      expected = num_questions_by_exercise_id[exercise['id']]
      got = exercise['points'].size

      errors.add(
        :settings,
        "- Expected the size of the points array for the Exercise with ID #{
        exercise['id']} to be #{expected}, but was #{got}"
      ) unless expected == got
    end

    throw(:abort) unless errors.empty?
  end

  def trim_text
    self.title&.strip!
    self.description&.strip!
  end

end
