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
    task_step = Tasks::Models::TaskStep.find(params[:id])
    tasked = task_step.tasked
    standard_read(tasked, Api::V1::TaskedRepresenterMapper.representer_for(tasked))
  end

  api :PUT, '/steps/:step_id', 'Updates the specified TaskStep'
  def update
    task_step = Tasks::Models::TaskStep.find(params[:id])
    tasked = task_step.tasked
    standard_update(tasked, Api::V1::TaskedRepresenterMapper.representer_for(tasked))
  end

  api :PUT, '/steps/:step_id/completed',
            'Marks the specified TaskStep as completed (if applicable)'
  def completed
    task_step = Tasks::Models::TaskStep.find(params[:id])
    tasked = task_step.tasked
    OSU::AccessPolicy.require_action_allowed!(:mark_completed,
                                              current_api_user,
                                              tasked)

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
    tasked = Tasks::Models::TaskStep.find(params[:id]).tasked
    OSU::AccessPolicy.require_action_allowed!(:recover,
                                              current_api_user,
                                              tasked)

    result = RecoverTaskedExercise.call(tasked_exercise: tasked)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs.recovery_step.tasked,
                   responder: ResponderWithPutContent
    end
  end

  api :PUT, '/steps/:step_id/refresh',
            'Requests an exercise similar to the given one for credit recovery'
  def refresh
    tasked = TaskStep.find(params[:id]).tasked
    OSU::AccessPolicy.require_action_allowed!(:refresh, current_api_user, tasked)

    result = RefreshTaskedExercise.call(tasked_exercise: tasked)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      json_response = {}
      json_response[:refresh_step] = result.outputs.refresh_step
      tasked = result.outputs.recovery_step.tasked
      representer = Api::V1::TaskedExerciseRepresenter.new(tasked)
      json_response[:recovery_step] = representer
      render json: json_response, responder: ResponderWithPutContent
    end
  end

end
