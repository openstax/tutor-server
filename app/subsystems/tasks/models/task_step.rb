class Tasks::Models::TaskStep < Tutor::SubSystems::BaseModel
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps
  belongs_to :tasked, polymorphic: true, dependent: :destroy

  enum group_type: [:default_group, :core_group, :spaced_practice_group]

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true

  def complete
    self.completed_at ||= Time.now
  end

  def completed?
    !self.completed_at.nil?
  end
end
