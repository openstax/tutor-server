class ExerciseStep < ActiveRecord::Base
  sortable_belongs_to :exercise, on: :number,
                                 class_name: 'TaskStep::Exercise',
                                 inverse_of: :exercise_steps
  belongs_to :step, polymorphic: true, dependent: :destroy

  validates :step, presence: true
  validates :step_id, uniqueness: { scope: :step_type }
  validates :exercise, presence: true

  def complete
    self.completed_at ||= Time.now
  end

  def completed?
    !self.completed_at.nil?
  end
end
