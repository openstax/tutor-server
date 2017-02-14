class Api::V1::TaskStepsController < Api::V1::ApiController

  before_filter :get_task_step

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
    standard_read(@tasked, Api::V1::TaskedRepresenterMapper.representer_for(@tasked), true)
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/steps/:step_id', 'Updates the specified TaskStep'
  def update
    standard_update(@tasked, Api::V1::TaskedRepresenterMapper.representer_for(@tasked))
  end

  ###############################################################
  # completed
  ###############################################################

  api :PUT, '/steps/:step_id/completed',
            'Marks the specified TaskStep as completed (if applicable)'
  def completed
    OSU::AccessPolicy.require_action_allowed!(:mark_completed, current_api_user, @tasked)

    result = MarkTaskStepCompleted.call(task_step: @task_step)

    render_api_errors(result.errors) || respond_with(
      @task_step.reload,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::TaskStepRepresenter
    )
  end

  ###############################################################
  # recovery
  ###############################################################

  api :PUT, '/steps/:step_id/recovery',
            'Requests a new exercise related to the given step'
  def recovery
    OSU::AccessPolicy.require_action_allowed!(:related_exercise, current_api_user, @tasked)

    result = Tasks::AddRelatedExerciseAfterStep.call(task_step: @task_step)

    render_api_errors(result.errors) || respond_with(
      result.outputs.related_exercise_step,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::TaskStepRepresenter
    )
  end

  protected

  def get_task_step
    Tasks::Models::TaskStep.transaction do
      @task_step = Tasks::Models::TaskStep.with_deleted.lock.find_by(id: params[:id])

      if @task_step.present?
        @tasked = @task_step.tasked
      else
        render_api_errors(:no_exercises, :not_found)
      end
    end
  end

end
