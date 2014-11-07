class TaskPlan < ActiveRecord::Base

  belongs_to :assistant
  belongs_to :owner, polymorphic: true

  has_many :tasking_plans, dependent: :destroy
  has_many :tasks, dependent: :destroy

  serialize :configuration

  validates :owner, presence: true
  validates :assistant, presence: true
  validates :configuration, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true

end
