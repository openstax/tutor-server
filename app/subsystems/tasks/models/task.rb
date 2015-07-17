require_relative '../placeholder_strategies/homework_personalized'
require_relative '../placeholder_strategies/i_reading_personalized'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel
  enum task_type: [:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice, :external]

  belongs_to :task_plan
  belongs_to :entity_task, class_name: 'Entity::Task',
                           dependent: :destroy,
                           foreign_key: 'entity_task_id'

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 autosave: true,
                                 inverse_of: :task
  has_many :taskings, through: :entity_task

  serialize :settings, JSON

  validates :title, presence: true

  validates :opens_at, presence: true, timeliness: { type: :date }

  # Practice Widget can create tasks with no due date
  # We already validate dates for teacher-created assignments in the TaskingPlan
  validates :due_at, timeliness: { type: :date }, allow_nil: true

  validate :due_at_on_or_after_opens_at

  after_initialize :post_init

  def post_init
    self.settings ||= {}
    self.settings['los'] ||= []
    self.settings['aplos'] ||= []
  end

  def los
    settings['los']
  end

  def los=(new_los)
    self.settings['los'] = new_los
  end

  def aplos
    settings['aplos']
  end

  def aplos=(new_aplos)
    self.settings['aplos'] = new_aplos
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

  def past_open?(current_time: Time.now)
    opens_at.nil? || current_time > opens_at
  end

  def past_due?(current_time: Time.now)
    !due_at.nil? && current_time > due_at
  end

  def feedback_available?(current_time: Time.now)
    !feedback_at.nil? && current_time >= feedback_at
  end

  def completed?
    steps_count == completed_steps_count
  end

  def status
    # task is "completed" if all steps are completed,
    #         "in_progress" if some steps are completed and
    #         "not_started" if no steps are completed
    if self.completed?
      'completed'
    else
      in_progress = (completed_steps_count > 0)
      in_progress ? 'in_progress' : 'not_started'
    end
  end

  def practice?
    page_practice? || chapter_practice? || mixed_practice?
  end

  def core_task_steps
    self.task_steps.preload(:tasked).to_a.select(&:core_group?)
  end

  def non_core_task_steps
    self.task_steps.preload(:tasked).to_a - self.core_task_steps
  end

  def spaced_practice_task_steps
    self.task_steps.preload(:tasked).to_a.select(&:spaced_practice_group?)
  end

  def personalized_task_steps
    self.task_steps.preload(:tasked).to_a.select(&:personalized_group?)
  end

  def core_task_steps_completed?
    core_steps_count == completed_core_steps_count
  end

  def core_task_steps_completed_at
    return nil unless self.core_task_steps_completed?
    self.core_task_steps.collect{|ts| ts.completed_at}.max
  end

  def handle_task_step_completion!(completion_time: Time.now)
    update_step_counts!

    if core_task_steps_completed? && placeholder_steps_count > 0
      strategy = personalized_placeholder_strategy
      unless strategy.nil?
        strategy.populate_placeholders(task: self)
      end

      update_step_counts!
    end
  end

  def update_step_counts!
    steps = self.task_steps.to_a

    update_steps_count(task_steps: steps)
    update_completed_steps_count(task_steps: steps)
    update_core_steps_count(task_steps: steps)
    update_completed_core_steps_count(task_steps: steps)
    update_exercise_steps_count(task_steps: steps)
    update_completed_exercise_steps_count(task_steps: steps)
    update_correct_exercise_steps_count(task_steps: steps)
    update_placeholder_steps_count(task_steps: steps)
    update_placeholder_exercise_steps_count(task_steps: steps)

    save!

    self
  end

  def exercise_count
    exercise_steps_count
  end

  def actual_and_placeholder_exercise_count
    exercise_steps_count + placeholder_exercise_steps_count
  end

  def completed_exercise_count
    completed_exercise_steps_count
  end

  def correct_exercise_count
    correct_exercise_steps_count
  end

  def exercise_steps
    task_steps.preload(:tasked).select{|task_step| task_step.exercise?}
  end

  def completed_exercise_steps
    exercise_steps.select{|step| step.completed?}
  end

  protected

  def due_at_on_or_after_opens_at
    return if due_at.nil? || opens_at.nil? || due_at >= opens_at
    errors.add(:due_at, 'must be on or after opens_at')
    false
  end

  def update_steps_count(task_steps:)
    self.steps_count = task_steps.count
  end

  def update_completed_steps_count(task_steps:)
    self.completed_steps_count = task_steps.count(&:completed?)
  end

  def update_core_steps_count(task_steps:)
    self.core_steps_count = task_steps.count(&:core_group?)
  end

  def update_completed_core_steps_count(task_steps:)
    self.completed_core_steps_count =
      task_steps.count{|step| step.core_group? && step.completed?}
  end

  def update_exercise_steps_count(task_steps:)
    self.exercise_steps_count = task_steps.count(&:exercise?)
  end

  def update_completed_exercise_steps_count(task_steps:)
    self.completed_exercise_steps_count =
      task_steps.count{|step| step.exercise? && step.completed?}
  end

  def update_correct_exercise_steps_count(task_steps:)
    self.correct_exercise_steps_count =
      task_steps.count{|step| step.exercise? && step.tasked.is_correct?}
  end

  def update_placeholder_steps_count(task_steps:)
    self.placeholder_steps_count = task_steps.count(&:placeholder?)
  end

  def update_placeholder_exercise_steps_count(task_steps:)
    self.placeholder_exercise_steps_count =
      task_steps.count{|step| step.placeholder? && step.tasked.exercise_type?}
  end

end
