class Tasks::Models::TaskingPlan < ApplicationRecord
  belongs_to_time_zone :opens_at, :due_at, :closes_at, suffix: :ntz

  belongs_to :task_plan, inverse_of: :tasking_plans, touch: true
  belongs_to :target, polymorphic: true

  validates :task_plan, uniqueness: { scope: [ :target_type, :target_id ] }

  validates :opens_at_ntz, :due_at_ntz, :closes_at_ntz, presence: true, timeliness: { type: :date }

  validate :due_at_in_the_future, :due_at_on_or_after_opens_at, :closes_at_on_or_after_due_at,
           :opens_after_course_starts, :closes_before_course_ends, :owner_can_task_target

  def past_open?(current_time: Time.current)
    opens_at.nil? || current_time > opens_at
  end

  def past_due?(current_time: Time.current)
    !due_at.nil? && current_time > due_at
  end

  def past_close?(current_time: Time.current)
    !closes_at.nil? && current_time > closes_at
  end

  protected

  def due_at_in_the_future
    return if task_plan.try(:is_draft?) ||
              !due_at_ntz_changed? || due_at.nil? || due_at > Time.current

    errors.add(:due_at, 'cannot be set into the past')
    throw :abort
  end

  def due_at_on_or_after_opens_at
    return if due_at.nil? || opens_at.nil? || due_at > opens_at

    errors.add(:due_at, 'cannot be before opens_at')
    throw :abort
  end

  def closes_at_on_or_after_due_at
    return if closes_at.nil? || due_at.nil? || closes_at > due_at

    errors.add(:closes_at, 'cannot be before due_at')
    throw :abort
  end

  def opens_after_course_starts
    return if task_plan&.owner_type != 'CourseProfile::Models::Course' ||
              opens_at.nil? ||
              task_plan.owner.starts_at <= opens_at

    errors.add(:opens_at, 'cannot be before the course starts')
    throw :abort
  end

  def closes_before_course_ends
    return if task_plan&.owner_type != 'CourseProfile::Models::Course' ||
              closes_at.nil? ||
              task_plan.owner.ends_at >= closes_at

    errors.add(:closes_at, 'cannot be after the course ends')
    throw :abort
  end

  def owner_can_task_target
    return if task_plan.nil? ||
              target.nil? ||
              TargetAccessPolicy.action_allowed?(:task, task_plan.owner, target)

    errors.add(:target, 'cannot be assigned to')
    throw :abort
  end
end
