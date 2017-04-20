class Tasks::Models::TaskStep < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  sortable_belongs_to :task, -> { with_deleted }, on: :number, inverse_of: :task_steps, touch: true
  belongs_to :tasked, -> { with_deleted }, polymorphic: true, dependent: :destroy,
                                           inverse_of: :task_step, touch: true

  enum group_type: [
    :default_group,
    :core_group,
    :spaced_practice_group,
    :personalized_group,
    :recovery_group
  ]

  json_serialize :related_content, Hash, array: true
  json_serialize :related_exercise_ids, Integer, array: true
  json_serialize :labels, String, array: true

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true

  delegate :can_be_answered?, :has_correctness?, :has_content?, to: :tasked

  scope :complete,   -> { where{first_completed_at != nil} }
  scope :incomplete, -> { where{first_completed_at == nil} }

  scope :exercises,  -> { where{tasked_type == Tasks::Models::TaskedExercise.name} }

  # Lock the task instead, but don't explode if task is nil
  def lock!(*args)
    task.try! :lock!, *args

    super
  end

  def exercise?
    tasked_type == Tasks::Models::TaskedExercise.name
  end

  def placeholder?
    tasked_type == Tasks::Models::TaskedPlaceholder.name
  end

  def is_correct?
    has_correctness? ? tasked.is_correct? : nil
  end

  def can_be_recovered?
    related_exercise_ids.any?
  end

  def make_correct!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_correct!
  end

  def make_incorrect!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_incorrect!
  end

  def complete(completion_time: Time.current)
    self.first_completed_at ||= completion_time
    self.last_completed_at = completion_time
    self
  end

  def completed?
    !first_completed_at.nil?
  end

  def feedback_available?
    completed? && task.feedback_available?
  end

  def group_name
    group_type.sub(/_group\z/, '').gsub('_', ' ')
  end

  def add_related_content(related_content_hash)
    return if related_content_hash.nil?
    self.related_content << related_content_hash
  end

  def add_labels(labels)
    self.labels = [self.labels, labels].flatten.compact.uniq
  end

end
