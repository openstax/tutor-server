class Tasks::Models::Extension < ApplicationRecord
  belongs_to :task_plan, inverse_of: :extensions
  belongs_to :role, subsystem: :entity, inverse_of: :extensions

  has_one :task, inverse_of: :extension

  delegate :timezone, :time_zone, to: :task_plan
  has_timezone :due_at, :closes_at, suffix: :ntz

  validates :role, uniqueness: { scope: :tasks_task_plan_id }
  validates :due_at_ntz, :closes_at_ntz, presence: true, timeliness: { type: :date }

  validate :closes_at_on_or_after_due_at

  protected

  def closes_at_on_or_after_due_at
    return if task_plan&.course.nil? || closes_at.nil? || due_at.nil? || closes_at >= due_at

    errors.add :closes_at, 'must be on or after due_at'
    throw :abort
  end
end
