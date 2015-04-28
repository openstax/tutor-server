require_relative 'entity_extensions'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel

  enum task_type: [:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice]

  belongs_to :task_plan
  belongs_to :entity_task, class_name: 'Entity::Task',
                           dependent: :destroy,
                           foreign_key: 'entity_task_id'

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 autosave: true,
                                 inverse_of: :task
  has_many :taskings, dependent: :destroy, through: :entity_task

  validates :title, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at },
                     allow_nil: true,
                     if: :opens_at

  validate :opens_at_or_due_at

  def is_shared?
    taskings.size > 1
  end

  def past_due?(current_time: Time.now)
    !due_at.nil? && current_time > due_at
  end

  def feedback_available?(current_time: Time.now)
    !feedback_at.nil? && current_time >= feedback_at
  end

  def completed?
    self.task_steps.all?{|ts| ts.completed? }
  end

  def practice?
    page_practice? || chapter_practice? || mixed_practice?
  end

  def core_task_steps
    self.task_steps.select{|ts| ts.core_group?}
  end

  def spaced_practice_task_steps
    self.task_steps.select{|ts| ts.spaced_practice_group?}
  end

  def core_task_steps_completed?
    self.core_task_steps.all?{|ts| ts.completed?}
  end

  def core_task_steps_completed_at
    return nil unless self.core_task_steps_completed?
    self.core_task_steps.collect{|ts| ts.completed_at}.max
  end

  def handle_task_step_completion!(completion_time: Time.now)
  end

  def exercise_count
    exercise_steps.count
  end

  def complete_exercise_count
    exercise_steps.complete.count
  end

  def correct_exercise_count
    exercise_steps.select{|step| step.tasked.is_correct?}.count
  end

  def exercise_steps
    task_steps.where{tasked_type.in %w(Tasks::Models::TaskedExercise)}
  end

  protected

  def opens_at_or_due_at
    return unless opens_at.blank? && due_at.blank?
    errors.add(:base, 'needs either the opens_at date or due_at date')
    false
  end

end
