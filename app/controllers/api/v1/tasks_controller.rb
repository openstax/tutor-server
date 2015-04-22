class Api::V1::TasksController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a task assigned to a user or role'
    description <<-EOS
      Tasks are a high-level representation of something that a user
      needs to do in the system (something that has been assigned by
      another part of the system).  They contain dates like due_at as
      well as information about whether the task is shared and the
      (optional) TaskPlan that may have helped generate it.  In addition
      to recording who the task is assigned to (the "taskable") a Task
      also records a set of details specific to a certain kind of task.
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/tasks/:id', 'Gets the specified Task'
  # description <<-EOS
  #   #{json_schema(Api::V1::TaskRepresenter, include: :readable)}
  # EOS
  def show
    standard_read(Tasks::Models::Task.find(params[:id]), Api::V1::TaskRepresenter, true)
  end

end
