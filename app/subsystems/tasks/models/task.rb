require_relative 'entity_extensions'

require_relative '../placeholder_strategies/homework_personalized'
require_relative '../placeholder_strategies/i_reading_personalized'

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

  serialize :settings, JSON

  validates :title, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at },
                     allow_nil: true,
                     if: :opens_at

  validate :opens_at_or_due_at

  after_initialize :post_init

  def post_init
    self.settings ||= {}
    self.settings['los'] ||= []
  end

  def los
    settings['los']
  end

  def los=(new_los)
    self.settings['los'] = new_los
    los
  end

  def personalized_placeholder_strategy
    serialized_strategy = read_attribute(:personalized_placeholder_strategy)
    strategy = serialized_strategy.nil? ? nil : YAML.load(serialized_strategy)
    strategy
  end

  def personalized_placeholder_strategy=(strategy)
    serialized_strategy = strategy.nil? ? nil : YAML.dump(strategy)
    write_attribute(:personalized_placeholder_strategy, serialized_strategy)
  end

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
    self.task_steps(true).all?{|ts| ts.completed? }
  end

  def status
    # task is "completed" if all steps are completed,
    #         "in_progress" if some steps are completed and
    #         "not_started" if no steps are completed
    if self.completed?
      'completed'
    else
      in_progress = self.task_steps.any? { |ts| ts.completed? }
      in_progress ? 'in_progress' : 'not_started'
    end
  end

  def practice?
    page_practice? || chapter_practice? || mixed_practice?
  end

  def core_task_steps
    self.task_steps(true).includes(:tasked).core_group
  end

  def non_core_task_steps
    self.task_steps(true).includes(:tasked) - self.core_task_steps
  end

  def spaced_practice_task_steps
    self.task_steps(true).includes(:tasked).spaced_practice_group
  end

  def personalized_task_steps
    self.task_steps(true).includes(:tasked).personalized_group
  end

  def core_task_steps_completed?
    self.core_task_steps.all?{|ts| ts.completed?}
  end

  def core_task_steps_completed_at
    return nil unless self.core_task_steps_completed?
    self.core_task_steps.collect{|ts| ts.completed_at}.max
  end

  def handle_task_step_completion!(completion_time: Time.now)
    return unless core_task_steps_completed?

    strategy = personalized_placeholder_strategy
    unless strategy.nil?
      strategy.populate_placeholders(task: self)
    end
  end

  def exercise_count
    exercise_steps.count
  end

  def completed_exercise_count
    completed_exercise_steps.count
  end

  def correct_exercise_count
    exercise_steps.select{|step| step.tasked.is_correct?}.count
  end

  def exercise_steps
    task_steps(true).includes(:tasked).select{|task_step| task_step.exercise?}
  end

  def completed_exercise_steps
    exercise_steps.select{|step| step.completed?}
  end

  protected

  def opens_at_or_due_at
    return unless opens_at.blank? && due_at.blank?
    errors.add(:base, 'needs either the opens_at date or due_at date')
    false
  end

end
