class TaskPlan < ActiveRecord::Base

  belongs_to :owner, polymorphic: true

  has_many :tasking_plans, dependent: :destroy
  has_many :tasks, dependent: :destroy

  validates :owner, presence: true
  validates :assistant, presence: true
  validates :configuration, presence: true
  validates :assign_after, presence: true
  validates :assigned_at, timeliness: { on_or_after: :assign_after },
                          allow_nil: true

  scope :due, lambda {
    where{(assigned_at == nil) & (my{Time.now} > assign_after)}
  }

end
