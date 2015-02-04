class TaskStep::Exercise < ActiveRecord::Base
  has_one_task_step

  has_many :exercise_steps, inverse_of: :task_step_exercise
end
