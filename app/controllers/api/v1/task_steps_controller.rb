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

  api :GET, '/tasks/:task_id/steps/:step_id', 'Gets the specified TaskStep'
  def show
    task_step = TaskStep.find(params[:id])
    standard_read(task_step, Api::V1::TaskedRepresenterMapper.representer_for(task_step))
  end

  def update
    raise NotYetImplemented
  end

  api :GET, '/tasks/:task_id/steps/:step_id/completed', 'Marks the specified TaskStep as completed (if applicable)'
  def completed
    task_step = TaskStep.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:mark_completed, current_api_user, task_step)
    
    result = MarkTaskStepCompleted.call(task_step: task_step)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      head :ok
    end
  end

end