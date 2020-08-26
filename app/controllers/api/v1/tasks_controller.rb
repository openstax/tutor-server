class Api::V1::TasksController < Api::V1::ApiController
  around_action :with_task
  before_action :error_if_student_and_needs_to_pay

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

    Tasks::PopulatePlaceholderSteps[task: @task, lock_task: false]

    @task.task_steps.tap do |task_steps|
      ActiveRecord::Associations::Preloader.new.preload task_steps, [ :tasked, :page ]
    end

    standard_read ::Research::ModifiedTask[task: @task], Api::V1::TaskRepresenter
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

  def with_task
    ::Tasks::Models::Task.transaction do
      @task = ::Tasks::Models::Task.lock.find(params[:id])

      yield
    end
  end
end
