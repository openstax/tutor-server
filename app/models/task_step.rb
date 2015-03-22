class TaskStep < ActiveRecord::Base
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps
  belongs_to :tasked, polymorphic: true, dependent: :destroy

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_name, presence: true

  delegate :tasked_to?, to: :task

  def complete(completion_time: Time.now)
    self.completed_at ||= completion_time
  end

  def completed?
    !self.completed_at.nil?
  end

  def is_core?
    self.group_name == 'core'
  end

  def mark_as_core
    self.group_name = 'core'
  end

  def is_spaced_practice?
    self.group_name == 'spaced_practice'
  end

  def mark_as_spaced_practice
    self.group_name = 'spaced_practice'
  end
end
