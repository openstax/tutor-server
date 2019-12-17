require 'json-schema'

class Tasks::Models::TaskPlan < ApplicationRecord
  acts_as_paranoid column: :withdrawn_at, without_default_scope: true

  UPDATEABLE_ATTRIBUTES_AFTER_OPEN = [
    'title', 'description', 'first_published_at', 'last_published_at'
  ]

  attr_accessor :is_publish_requested

  # Allow use of 'type' column without STI
  self.inheritance_column = nil

  belongs_to :cloned_from, foreign_key: 'cloned_from_id',
                           class_name: 'Tasks::Models::TaskPlan',
                           optional: true

  belongs_to :assistant
  belongs_to :owner, polymorphic: true
  belongs_to :ecosystem, subsystem: :content
  belongs_to :grading_template, optional: true, inverse_of: :task_plans

  # These associations to not have dependent: :destroy because the task_plan is soft-deleted
  has_many :tasking_plans, inverse_of: :task_plan
  has_many :tasks, inverse_of: :task_plan

  json_serialize :settings, Hash

  before_validation :trim_text, :set_ecosystem

  validates :title, presence: true
  validates :type, presence: true
  validates :tasking_plans, presence: true

  validate :valid_settings,
           :same_ecosystem,
           :has_grading_template_if_gradable,
           :grading_template_same_course,
           :grading_template_type_matches,
           :changes_allowed,
           :not_past_due_when_publishing

  scope :tasked_to_period_id, ->(period_id) do
    joins(:tasking_plans).where(
      tasking_plans: { target_id: period_id, target_type: 'CourseMembership::Models::Period' }
    )
  end

  scope :published,     -> { where.not first_published_at: nil }
  scope :non_withdrawn, -> { where withdrawn_at: nil }

  scope :preload_tasking_plans, -> { preload(tasking_plans: :time_zone) }

  scope :preload_tasks, -> { preload(tasks: :time_zone) }

  def auto_grading_feedback_on
    grading_template.nil? ? 'answer' : grading_template.auto_grading_feedback_on
  end

  def manual_grading_feedback_on
    grading_template.nil? ? 'grade' : grading_template.manual_grading_feedback_on
  end

  def withdrawn?
    deleted?
  end

  def out_to_students?(current_time: Time.current)
    tasks.reject(&:preview?).any? { |task| task.past_open?(current_time: current_time) }
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

  protected

  def get_ecosystems_from_exercise_ids
    ecosystems = Content::Models::Ecosystem.distinct.joins(:exercises).where(
      exercises: { id: settings['exercise_ids'] }
    ).to_a
  end

  def get_ecosystems_from_page_ids
    ecosystems = Content::Models::Ecosystem.distinct.joins(:pages).where(
      pages: { id: settings['page_ids'] }
    ).to_a
  end

  def get_ecosystems_from_settings
    if settings['exercise_ids'].present?
      get_ecosystems_from_exercise_ids
    elsif settings['page_ids'].present?
      get_ecosystems_from_page_ids
    end
  end

  def set_ecosystem
    self.ecosystem ||= cloned_from&.ecosystem ||
                       get_ecosystems_from_settings&.first ||
                       owner.try(:ecosystems)&.first
  end

  def valid_settings
    schema = assistant.try(:schema)
    return if schema.blank?

    json_errors = JSON::Validator.fully_validate(schema, settings, insert_defaults: true)
    return if json_errors.empty?

    json_errors.each { |json_error| errors.add(:settings, "- #{json_error}") }
    throw :abort
  end

  def same_ecosystem
    return if ecosystem.nil?

    # Special checks for the page_ids and exercise_ids settings
    errors.add(:settings, '- Invalid exercises selected') \
      if settings['exercise_ids'].present? && get_ecosystems_from_exercise_ids != [ ecosystem ]

    errors.add(:settings, '- Invalid pages selected') \
      if settings['page_ids'].present? && get_ecosystems_from_page_ids != [ ecosystem ]

    throw(:abort) if errors.any?
  end

  def has_grading_template_if_gradable
    return unless [ 'reading', 'homework' ].include?(type) && grading_template.nil?

    errors.add :grading_template, 'must be present for readings and homeworks'
    throw :abort
  end

  def grading_template_same_course
    return if grading_template.nil? || grading_template.course == owner

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

  def not_past_due_when_publishing
    return if !is_publish_requested || tasking_plans.none?(&:past_due?)

    errors.add :due_at, 'cannot be in the past when publishing'
    throw :abort
  end

  def trim_text
    self.title&.strip!
    self.description&.strip!
  end
end
