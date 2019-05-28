require 'json-schema'

class Tasks::Models::TaskPlan < ApplicationRecord

  acts_as_paranoid column: :withdrawn_at, without_default_scope: true

  UPDATABLE_ATTRIBUTES_AFTER_OPEN = [
    'title', 'description', 'first_published_at', 'last_published_at', 'is_feedback_immediate'
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

  has_many :tasking_plans, inverse_of: :task_plan
  has_many :tasks, inverse_of: :task_plan

  json_serialize :settings, Hash

  before_validation :trim_text

  validates :title, presence: true
  validates :type, presence: true
  validates :tasking_plans, presence: true

  validate :valid_settings, :same_ecosystem, :changes_allowed, :not_past_due_when_publishing

  before_validation :set_ecosystem

  scope :preload_tasking_plans, -> { preload(tasking_plans: :time_zone) }

  scope :preload_tasks, -> { preload(tasks: :time_zone) }

  def withdrawn?
    deleted?
  end

  def out_to_students?(current_time: Time.current)
    tasks.any? do |task|
      task.past_open?(current_time: current_time) && !task.preview?
    end
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

  def get_ecosystem_from_exercise_ids
    Content::Ecosystem.find_by_exercise_ids(*settings['exercise_ids']).try!(:to_model)
  end

  def get_ecosystem_from_page_ids
    Content::Ecosystem.find_by_page_ids(*settings['page_ids']).try!(:to_model)
  end

  def get_ecosystem_from_settings
    if settings['exercise_ids'].present?
      get_ecosystem_from_exercise_ids
    elsif settings['page_ids'].present?
      get_ecosystem_from_page_ids
    end
  end

  def set_ecosystem
    self.ecosystem ||= cloned_from.try!(:ecosystem) ||
                       get_ecosystem_from_settings ||
                       owner.try(:ecosystems).try(:first)
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
      if settings['exercise_ids'].present? && ecosystem != get_ecosystem_from_exercise_ids

    errors.add(:settings, '- Invalid pages selected') \
      if settings['page_ids'].present? && ecosystem != get_ecosystem_from_page_ids

    throw(:abort) if errors.any?
  end

  def changes_allowed
    forbidden_attributes = changes.except(*UPDATABLE_ATTRIBUTES_AFTER_OPEN)
    return if forbidden_attributes.empty?
    return unless out_to_students?

    forbidden_attributes.each do |key, value|
      errors.add(key.to_sym, "cannot be updated after the open date")
    end

    throw :abort
  end

  def not_past_due_when_publishing
    return if !is_publish_requested || tasking_plans.none?(&:past_due?)

    errors.add(:due_at, 'cannot be in the past when publishing')
    throw :abort
  end

  def trim_text
    self.title.try(:strip!)
    self.description.try(:strip!)
  end

end
