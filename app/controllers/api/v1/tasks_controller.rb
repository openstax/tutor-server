class Api::V1::TasksController < Api::V1::ApiController

  before_filter :get_task, only: [:show]

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
  description <<-EOS
    Gets the task with the specified ID.

    Schema coming soon.         
  EOS
  # TODO: Figure out how to print a schema that covers all task types
  def show
    standard_read(@task, TaskRepresenterMapper.new.call(self, @task))
  end

  protected

  def get_task
    @task = Task.find(params[:id])
  end

end