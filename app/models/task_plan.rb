class TaskPlan < ActiveRecord::Base

  belongs_to :assistant
  belongs_to :owner, polymorphic: true

  has_many :tasking_plans, dependent: :destroy
  has_many :tasks, dependent: :destroy

  serialize :configuration

  validates :owner, presence: true
  validates :assistant, presence: true
  validates :type, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true

  # A TaskPlan cannot validate its configuration -- only the Assistant or its
  # delegate can do that

  # Allow use of 'type' column without STI
  self.inheritance_column = nil

  def configuration
    Hashie::Mash.new(read_attribute(:configuration))
  end

end
