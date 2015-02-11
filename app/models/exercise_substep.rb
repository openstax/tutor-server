class ExerciseSubstep < ActiveRecord::Base
  sortable_belongs_to :tasked_exercise, on: :number,
                                        inverse_of: :exercise_substeps
  belongs_to :subtasked, polymorphic: true, dependent: :destroy

  validates :subtasked, presence: true
  validates :subtasked_id, uniqueness: { scope: :subtasked_type }
  validates :tasked_exercise, presence: true

  def complete
    self.completed_at ||= Time.now
  end

  def completed?
    !self.completed_at.nil?
  end
end
