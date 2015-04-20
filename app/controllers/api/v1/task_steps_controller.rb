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
    tasked = Tasks::Models::TaskStep.find(params[:id]).tasked
    standard_read(tasked, Api::V1::TaskedRepresenterMapper.representer_for(tasked), true)
  end

  api :PUT, '/steps/:step_id', 'Updates the specified TaskStep'
  def update
    tasked = Tasks::Models::TaskStep.find(params[:id]).tasked
    standard_update(tasked, Api::V1::TaskedRepresenterMapper.representer_for(tasked))
  end

  api :PUT, '/steps/:step_id/completed',
            'Marks the specified TaskStep as completed (if applicable)'
  def completed
    task_step = Tasks::Models::TaskStep.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:mark_completed, current_api_user, tasked)

    result = MarkTaskStepCompleted.call(task_step: task_step)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with tasked.reload, 
                   responder: ResponderWithPutContent,
                   represent_with: Api::V1::TaskedRepresenterMapper.representer_for(tasked)
    end
  end

  api :PUT, '/steps/:step_id/recovery',
            'Requests an exercise similar to the given one for credit recovery'
  def recovery
    task_step = Tasks::Models::TaskStep.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:recover, current_api_user, tasked)

    result = Tasks::RecoverTaskStep[task_step: task_step]

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with tasked,
                   responder: ResponderWithPutContent,
                   represent_with: Api::V1::TaskedRepresenterMapper.representer_for(tasked)
    end
  end

  api :PUT, '/steps/:step_id/refresh',
            "Requests another resource to refresh the student's memory, as well as an exercise similar to the given one for credit recovery"
  description <<-EOS
    #{json_schema(Api::V1::RefreshRepresenter, include: :readable)}
  EOS
  def refresh
    task_step = Tasks::Models::TaskStep.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:refresh, current_api_user, tasked)

    result = Tasks::RefreshTaskStep[task_step: task_step]

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs, represent_with: Api::V1::RefreshRepresenter,
                                   responder: ResponderWithPutContent
    end
  end

end
