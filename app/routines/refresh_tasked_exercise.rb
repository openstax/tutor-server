class RefreshTaskedExercise

  lev_routine

  uses_routine RecoverTaskedExercise,
               as: :recover, translations: { outputs: { type: :verbatim } }

  protected

  def exec(tasked_exercise:)
    task_step = tasked_exercise.task_step
    run(:recover, tasked_exercise: tasked_exercise)
    task = outputs[:task]
    recovery_step = outputs[:recovery_step]

    outputs[:refresh_step] = refresh_step_for(task_step: task_step)
  end

  private

  def refresh_step_for(task_step:)
    current_step = task_step

    # Hack for Sprint 9; Replace with final version before alpha
    while current_step.tasked_type.demodulize != 'TaskedReading' do
      current_step = current_step.previous_by_number
      return {} if current_step.nil?
    end

    { url: current_step.tasked.url }
  end

end
