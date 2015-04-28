class Tasks::Models::TaskStep < Tutor::SubSystems::BaseModel
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps, touch: true
  belongs_to :tasked, polymorphic: true, dependent: :destroy, inverse_of: :task_step, touch: true

  enum group_type: [:default_group, :core_group, :spaced_practice_group]

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true

  delegate :can_be_answered?, :can_be_recovered?, :exercise?, to: :tasked

  scope :complete, -> { where{completed_at != nil} }
  scope :incomplete, -> { where{completed_at == nil} }

  def complete(completion_time: Time.now)
    self.completed_at ||= completion_time
  end

  def completed?
    !self.completed_at.nil?
  end

  def feedback_available?
    completed? && task.feedback_available?
  end
end
