require 'json-schema'

class Tasks::Models::TaskPlan < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  UPDATABLE_ATTRIBUTES_AFTER_OPEN = ['title', 'description', 'first_published_at',
                                     'last_published_at', 'is_feedback_immediate']

  attr_accessor :is_publish_requested

  # Allow use of 'type' column without STI
  self.inheritance_column = nil

  belongs_to :cloned_from, class_name: 'Tasks::Models::TaskPlan'

  belongs_to :assistant
  belongs_to :owner, polymorphic: true
  belongs_to :ecosystem, subsystem: :content

  has_many :tasking_plans, -> { with_deleted }, dependent: :destroy, inverse_of: :task_plan
  has_many :tasks, -> { with_deleted }, dependent: :destroy, inverse_of: :task_plan

  json_serialize :settings, Hash

  before_validation :trim_text

  validates :title, presence: true
  validates :assistant, presence: true
  validates :ecosystem, presence: true
  validates :owner, presence: true
  validates :type, presence: true
  validates :tasking_plans, presence: true

  validate :valid_settings, :same_ecosystem, :changes_allowed, :not_past_due_when_publishing

  scope :preloaded, -> { preload(:owner, :tasking_plans, tasks: [:taskings, task_steps: :tasked]) }

  def tasks_past_open?
    tasks.any?(&:past_open?)
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

  protected

  def valid_settings
    schema = assistant.try(:schema)
    return if schema.blank?

    json_errors = JSON::Validator.fully_validate(schema, settings, insert_defaults: true)
    return if json_errors.empty?
    json_errors.each{ |json_error| errors.add(:settings, "- #{json_error}") }
    false
  end

  def same_ecosystem
    return if ecosystem.nil?
    ecosystem_wrapper = Content::Ecosystem.new(strategy: ecosystem.wrap)

    return_value = nil
    # Special checks for the page_ids and exercise_ids settings
    if settings['exercise_ids'].present?
      exercises_ecosystem = Content::Ecosystem.find_by_exercise_ids(*settings['exercise_ids'])
      if exercises_ecosystem != ecosystem_wrapper
        errors.add(:settings, '- Invalid exercises selected')
        return_value = false
      end
    end

    if settings['page_ids'].present?
      pages_ecosystem = Content::Ecosystem.find_by_page_ids(*settings['page_ids'])
      if pages_ecosystem != ecosystem_wrapper
        errors.add(:settings, '- Invalid pages selected')
        return_value = false
      end
    end

    return_value
  end

  def changes_allowed
    return unless tasks_past_open?
    forbidden_attributes = changes.except(*UPDATABLE_ATTRIBUTES_AFTER_OPEN)
    return if forbidden_attributes.empty?

    forbidden_attributes.each do |key, value|
      errors.add(key.to_sym, "cannot be updated after the open date")
    end

    false
  end

  def not_past_due_when_publishing
    return if !is_publish_requested || tasking_plans.none?(&:past_due?)
    errors.add(:due_at, 'cannot be in the past when publishing')
    false
  end

  def trim_text
    self.title.try(:strip!)
    self.description.try(:strip!)
  end

end
