class Tasks::Models::TaskedPlaceholder < ApplicationRecord
  attr_writer :available_points

  acts_as_tasked

  enum placeholder_type: [:unknown_type, :exercise_type]

  validates :placeholder_type, presence: true

  def placeholder?
    true
  end

  def is_correct?
    false
  end

  def completed?
    false
  end

  def can_be_auto_graded?
    true
  end

  def available_points
    @available_points ||= begin
      task = task_step.task
      if task.homework?
        # Inefficient, which is why we preload the available_points in the TaskRepresenter
        task_question_index = task.task_steps.filter(&:exercise?).index(self)
        task.available_points_per_question_index[task_question_index]
      else
        1.0
      end
    end
  end
end
