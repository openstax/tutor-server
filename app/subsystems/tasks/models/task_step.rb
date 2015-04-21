class Tasks::Models::TaskStep < Tutor::SubSystems::BaseModel
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps, touch: true
  belongs_to :tasked, polymorphic: true, dependent: :destroy, inverse_of: :task_step, touch: true

  enum group_type: [:default_group, :core_group, :spaced_practice_group]

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true

  delegate :can_be_answered?, :can_be_recovered?, to: :tasked

  scope :complete, -> { where{completed_at != nil} }
  scope :incomplete, -> { where{completed_at == nil} }

  def has_correctness?
    tasked.has_correctness?
  end

  def is_correct?
    return nil unless has_correctness?
    tasked.is_correct?
  end

  def make_correct!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_correct!
  end

  def make_incorrect!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_incorrect!
  end

  def complete(completion_time: Time.now)
    self.completed_at ||= completion_time
  end

  def completed?
    !self.completed_at.nil?
  end

  def feedback_available?
    completed? && task.feedback_available?
  end

  def placeholder?
    self.tasked_type.demodulize == 'TaskedPlaceholder'
  end
end
