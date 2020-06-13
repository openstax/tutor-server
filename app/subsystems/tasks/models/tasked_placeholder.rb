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
        task_question_index = task.exercise_and_placeholder_steps.index(task_step)
        task.available_points_per_question_index[task_question_index]
      else
        1.0
      end
    end
  end

  def points_without_lateness
    # Behaves like an ungraded incomplete exercise step
    task_step.task.past_due? ? 0.0 : nil
  end
  alias_method :published_points_without_lateness, :points_without_lateness
end
