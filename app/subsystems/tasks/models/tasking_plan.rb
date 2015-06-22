class Tasks::Models::TaskingPlan < Tutor::SubSystems::BaseModel

  belongs_to :task_plan, inverse_of: :tasking_plans
  belongs_to :target, polymorphic: true

  validates :target, presence: true
  validates :task_plan, presence: true,
                        uniqueness: { scope: [:target_type, :target_id] }

  validates :due_at, timeliness: { on_or_after: :opens_at },
                     allow_nil: true,
                     if: :opens_at

  validate :opens_at_or_due_at, :owner_can_task_target

  protected

  def opens_at_or_due_at
    return unless opens_at.blank? && due_at.blank?
    errors.add(:base, 'needs either the opens_at date or due_at date')
    false
  end

  def owner_can_task_target
    return if task_plan.nil? || target.nil? || \
              TargetAccessPolicy.action_allowed?(:task, task_plan.owner, target)
    errors.add(:target, 'cannot be assigned to')
    false
  end

end
