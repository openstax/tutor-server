class Tasks::Models::PracticeQuestion < ApplicationRecord
  belongs_to :tasked_exercise, subsystem: :tasks
  belongs_to :exercise, subsystem: :content
  belongs_to :role, subsystem: :entity, inverse_of: :practice_questions

  validates :tasks_tasked_exercise_id, presence: true,
                                       uniqueness: { scope: [:tasks_tasked_exercise_id, :entity_role_id] }
  validates :content_exercise_id, presence: true,
                                  uniqueness: { scope: [:content_exercise_id, :entity_role_id] }

  def available?
    parts.all?(&:feedback_available?)
  end

  def parts
    return [tasked_exercise] unless tasked_exercise.is_in_multipart?

    task = tasked_exercise.task_step.task
    task.task_steps.exercises.preload(:tasked).map(&:tasked).select{|tasked| tasked.content_exercise_id == content_exercise_id }
  end
end
