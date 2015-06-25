require 'json-schema'

class Tasks::Models::TaskPlan < Tutor::SubSystems::BaseModel

  UPDATABLE_ATTRIBUTES = ['title', 'description']

  attr_accessor :is_publish_requested

  # Allow use of 'type' column without STI
  self.inheritance_column = nil

  belongs_to :assistant
  belongs_to :owner, polymorphic: true

  has_many :tasking_plans, dependent: :destroy, inverse_of: :task_plan
  has_many :tasks, dependent: :destroy

  serialize :settings, JSON

  validates :title, presence: true
  validates :assistant, presence: true
  validates :owner, presence: true
  validates :type, presence: true
  validates :tasking_plans, presence: true

  validate :valid_settings, :changes_allowed, :publish_requested_before_due

  protected

  def valid_settings
    schema = assistant.try(:schema)
    return if schema.blank?

    json_errors = JSON::Validator.fully_validate(schema, settings, insert_defaults: true)
    return if json_errors.empty?
    json_errors.each do |json_error|
      errors.add(:settings, "- #{json_error}")
    end
    false
  end

  def changes_allowed
    return if tasks.none? { |tt| tt.past_open? } || \
              (!is_publish_requested && changes.except(*UPDATABLE_ATTRIBUTES).empty?)
    action = is_publish_requested ? 'republished' : 'updated'
    errors.add(:base, "cannot be #{action} after it is open")
    false
  end

  def publish_requested_before_due
    return if !is_publish_requested || \
              tasking_plans.none? { |tp| !tp.due_at.nil? && tp.due_at < Time.now }
    errors.add(:due_at, 'cannot be in the past when publishing')
    false
  end

end
