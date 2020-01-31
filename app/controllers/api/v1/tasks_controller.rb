class Api::V1::TasksController < Api::V1::ApiController
  before_action :get_task
  before_action :error_if_student_and_needs_to_pay, only: [ :show, :destroy ]
  before_action :populate_placeholders, only: :show

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
    #{ json_schema Api::V1::TaskRepresenter, include: :readable }
  EOS
  def show
    ScoutHelper.ignore!(0.8)

    @task.task_steps.tap do |task_steps|
      ActiveRecord::Associations::Preloader.new.preload task_steps, [ :tasked, page: :chapter ]
    end

    standard_read ::Research::ModifiedTask[task: @task], Api::V1::TaskRepresenter
  end

  api :PUT, '/tasks/:id/accept_late_work', 'Accept late work in the task score'
  description <<-EOS
    Changes the Task so that it is marked as late work being accepted, and changes
    the `score` that it computes.  Does not change the underlying counts in any way.
  EOS
  def accept_late_work
    OSU::AccessPolicy.require_action_allowed! :accept_or_reject_late_work, current_api_user, @task

    @task.accept_late_work

    if @task.save
      head :no_content
    else
      render_api_errors @task.errors
    end
  end


  api :PUT, '/tasks/:id/reject_late_work', 'Reject late work in the task score'
  description <<-EOS
    Changes the Task so that it is marked as late work being not included, and changes
    the `score` that it computes.  Does not change the underlying counts in any way.
  EOS
  def reject_late_work
    OSU::AccessPolicy.require_action_allowed! :accept_or_reject_late_work, current_api_user, @task

    @task.reject_late_work

    if @task.save
      head :no_content
    else
      render_api_errors @task.errors
    end
  end

  api :DELETE, '/tasks/:id', 'Hide the task from the student\'s dashboard'
  description <<-EOS
    Hides the Task from the student's dashboard
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed! :hide, current_api_user, @task

    @task.hide.save!

    respond_with @task, represent_with: Api::V1::TaskRepresenter,
                        responder: ResponderWithPutPatchDeleteContent
  end

  protected

  def get_task
    @task = ::Tasks::Models::Task.find(params[:id])
  end

  def populate_placeholders
    Tasks::PopulatePlaceholderSteps[task: @task, skip_unready: @task.practice?]
  end
end
