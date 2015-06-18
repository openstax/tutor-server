require 'json-schema'

class Tasks::Models::TaskPlan < Tutor::SubSystems::BaseModel

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

  before_save :validate_settings

  def publish_last_requested_at
    published_at
  end

  def publish_last_requested_at=(val)
    self.published_at = val
  end

  protected

  def validate_settings
    schema = assistant.try(:schema)
    return if schema.blank?

    json_errors = JSON::Validator.fully_validate(schema, settings, insert_defaults: true)
    return if json_errors.empty?
    json_errors.each do |json_error|
      errors.add(:settings, "- #{json_error}")
    end
    false
  end

end
