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

  validates :assistant, presence: true
  validates :owner, presence: true
  validates :type, presence: true

  validate :valid_settings, :not_open

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

  def not_open
    return if tasks.none? { |tt| tt.opens_at.nil? || tt.opens_at <= Time.now } || \
              (!is_publish_requested && changes.except(*UPDATABLE_ATTRIBUTES).empty?)
    action = is_publish_requested ? 'republished' : 'updated'
    errors.add(:base, "cannot be #{action} after it is open")
    false
  end

end
