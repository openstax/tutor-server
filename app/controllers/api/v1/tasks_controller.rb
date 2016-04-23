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
    standard_read(::Tasks::Models::Task.find(params[:id]), Api::V1::TaskRepresenter, true)
  end

  api :PUT, '/tasks/:id/accept_late_work', 'Accept late work in the task score'
  description <<-EOS
    Changes the Task so that it is marked as late work being accepted, and changes
    the `score` that it computes.  Does not change the underlying counts in any way.
  EOS
  def accept_late_work
    change_is_late_work_accepted(true)
  end


  api :PUT, '/tasks/:id/reject_late_work', 'Reject late work in the task score'
  description <<-EOS
    Changes the Task so that it is marked as late work being not included, and changes
    the `score` that it computes.  Does not change the underlying counts in any way.
  EOS
  def reject_late_work
    change_is_late_work_accepted(false)
  end

  protected

  def change_is_late_work_accepted(is_accepted)
    task = Tasks::Models::Task.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:change_is_late_work_accepted, current_api_user, task)
    task.is_late_work_accepted = is_accepted
    task.save! # would be Exceptional if this failed
    head :ok
  end

end
