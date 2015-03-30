class Tasks::Models::TaskPlan < Tutor::SubSystems::BaseModel

  # Allow use of 'type' column without STI
  self.inheritance_column = nil

  belongs_to :assistant
  belongs_to :owner, polymorphic: true

  has_many :tasking_plans, dependent: :destroy
  has_many :tasks, dependent: :destroy

  serialize :settings, JSON

  validates :assistant, presence: true
  validates :owner, presence: true
  validates :type, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true

end
