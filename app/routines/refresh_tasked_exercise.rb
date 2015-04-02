# Move to task (do iReading) subsystem

class RefreshTaskedExercise

  lev_routine

  uses_routine RecoverTaskedExercise,
               as: :recover, translations: { outputs: { type: :verbatim } }

  protected

  def exec(tasked_exercise:)
    step = tasked_exercise.task_step
    run(:recover, tasked_exercise: tasked_exercise)
    task = outputs[:task]
    recovery_step = outputs[:recovery_step]

    # Hack for Sprint 9; Replace with final version before alpha
    while step.tasked_type.demodulize != 'TaskedReading' do
      step = step.previous_by_number
      return if step.nil?
    end

    outputs[:refresh_step] = { url: step.tasked.url }
  end
end
