class ExerciseStep < ActiveRecord::Base
  belongs_to :task_step_exercise, class_name: 'TaskStep::Exercise',
                                  inverse_of: :exercise_steps
  belongs_to :step, polymorphic: true, dependent: :destroy

  validates :step, presence: true
  validates :step_id, uniqueness: { scope: :step_type }
  validates :task_step_exercise, presence: true
  validates :number, presence: true,
                     uniqueness: { scope: :task_step_exercise_id },
                     numericality: true

  before_validation :assign_next_number

  def complete
    self.completed_at ||= Time.now
  end

  def completed?
    !self.completed_at.nil?
  end

  protected

  def assign_next_number
    self.number ||= (peers.max_by{|p| p.number || -1}
                          .try(:number) || -1) + 1
  end

  def peers
    task_step_exercise.try(:exercise_steps) || []
  end
end
