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

end