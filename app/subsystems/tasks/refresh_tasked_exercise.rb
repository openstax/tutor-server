class Tasks::RefreshTaskedExercise

  lev_routine

  uses_routine Tasks::RecoverTaskedExercise,
               as: :recover, translations: { outputs: { type: :verbatim } }

  protected

  def exec(tasked_exercise:)
    task_step = tasked_exercise.task_step
    run(:recover, tasked_exercise: tasked_exercise)

    outputs[:refresh_step] = refresh_step_for(task_step: task_step)
  end

  private

  def refresh_step_for(task_step:)
    current_step = task_step

    # Hack for Sprint 9; Replace with final version before MVP
    # This hack returns the last completed TaskedReading's URL,
    # which is the current CNX module's URL.
    # The FE is responsible for displaying it to the user.
    # Will not work if the exercise is the first step in an iReading
    # (but it shouldn't be)
    while current_step.tasked_type.demodulize != 'TaskedReading' do
      current_step = current_step.previous_by_number
      return {} if current_step.nil?
    end

    { url: current_step.tasked.url }
  end

end
