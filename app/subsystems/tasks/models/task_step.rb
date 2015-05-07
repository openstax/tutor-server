class Tasks::Models::TaskStep < Tutor::SubSystems::BaseModel
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps, touch: true
  belongs_to :tasked, polymorphic: true, dependent: :destroy, inverse_of: :task_step, touch: true

  enum group_type: [:default_group, :core_group, :spaced_practice_group, :personalized_group]

  serialize :settings, JSON

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true

  delegate :can_be_answered?, :can_be_recovered?, :exercise?, to: :tasked

  scope :complete, -> { where{completed_at != nil} }
  scope :incomplete, -> { where{completed_at == nil} }

  after_initialize :init_settings
  after_initialize :init_related_content

  def init_settings
    self.settings ||= {}
  end

  def init_related_content
    self.settings['related_content'] ||= []
  end

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

  def group_name
    group_type.gsub(/_group\z/, '').gsub('_', ' ')
  end

  def related_content
    self.settings['related_content']
  end

  def related_content=(value)
    self.settings['related_content'] = value
  end

  def add_related_content(related_content_hash)
    self.settings['related_content'] << related_content_hash
  end

end
