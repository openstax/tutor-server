class TaskStep < ActiveRecord::Base
  belongs_to :details, polymorphic: true, dependent: :destroy
  belongs_to :task

  validates :details, presence: true
  validates :details_id, uniqueness: { scope: :details_type }
  validates :task, presence: true
  validates :title, presence: true
  validates :number, presence: true, uniqueness: { scope: :task_id },
                     numericality: true

  before_validation :assign_next_number

  protected

  def assign_next_number
    return if task.nil?
    self.number ||= (task.task_steps.maximum(:number) || -1) + 1
  end
end
