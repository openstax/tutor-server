class Api::V1::TaskStepsController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a step in a task'
    description <<-EOS
      TBD
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/steps/:step_id', 'Gets the specified TaskStep'
  def show
    task_step = TaskStep.find(params[:id])
    standard_read(task_step.tasked)
  end

  api :PUT, '/steps/:step_id', 'Updates the specified TaskStep'
  def update
    task_step = TaskStep.find(params[:id])
    tasked = task_step.tasked
    standard_update(tasked)

    # TODO make a modified version of standard_update that returns the updated JSON
    # instead of the default PUT result of No Content 204.
  end

  api :GET, '/steps/:step_id/completed', 'Marks the specified TaskStep as completed (if applicable)'
  def completed
    task_step = TaskStep.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:mark_completed, current_api_user, task_step.tasked)

    result = MarkTaskStepCompleted.call(task_step: task_step)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      head :ok
    end
  end

end
