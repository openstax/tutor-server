class Tasks::Models::TaskingPlan < Tutor::SubSystems::BaseModel
  belongs_to :task_plan, inverse_of: :tasking_plans
  belongs_to :target, polymorphic: true

  validates :target, presence: true
  validates :task_plan, presence: true, uniqueness: { scope: [:target_type, :target_id] }

  validates :opens_at, presence: true, timeliness: { type: :date }
  validates :due_at, presence: true, timeliness: { type: :date }

  validate :due_at_on_or_after_opens_at

  validate :owner_can_task_target

  protected

  def due_at_on_or_after_opens_at
    return if due_at.nil? || opens_at.nil? || due_at >= opens_at
    errors.add(:due_at, 'must be on or after opens_at')
    false
  end

  def owner_can_task_target
    return if task_plan.nil? || target.nil? || \
              TargetAccessPolicy.action_allowed?(:task, task_plan.owner, target)
    errors.add(:target, 'cannot be assigned to')
    false
  end
end
