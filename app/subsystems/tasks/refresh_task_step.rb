class Tasks::RefreshTaskStep

  lev_routine outputs: { refresh_step: :_self },
              uses: { name: Tasks::RecoverTaskStep, as: :recover }

  protected

  def exec(task_step:)
    run(:recover, task_step: task_step)

    set(refresh_step: refresh_step_for(task_step: task_step))
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
