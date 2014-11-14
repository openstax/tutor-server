class TaskStep < ActiveRecord::Base
  belongs_to :details, polymorphic: true, dependent: :destroy
  belongs_to :task

  validates :details, presence: true
  validates :details_id, uniqueness: { scope: :details_type }
  validates :task, presence: true
  validates :title, presence: true
  validates :number, presence: true, uniqueness: { scope: :task_id },
                     numericality: true

  # TODO ponder integration of acts_as_numberable
  before_validation :assign_next_number

  protected

  def assign_next_number
    self.number ||= (peers.maximum(:number) || -1) + 1
  end

  def peers
    TaskStep.where(task_id: task_id)
  end
end
