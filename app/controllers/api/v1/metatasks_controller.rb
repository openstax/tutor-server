class Api::V1::MetatasksController < Api::V1::ApiController

  before_action :get_task
  before_filter :error_if_student_and_needs_to_pay, only: [:show, :destroy]
  before_action :populate_placeholders, only: :show

  resource_description do
    api_versions "v1"
    short_description 'Represents a metatask, a light weight task'
    description <<-EOS
      Metatasks are a light weight representation of something that a user
      needs to do in the system (something that has been assigned by
      another part of the system).  They contain dates like due_at as
      well as information about whether the task is shared
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/metatasks/:id', 'Gets the specified metatask'
  description <<-EOS
    #{json_schema(Api::V1::MetataskRepresenter, include: :readable)}
  EOS
  def show
    ScoutHelper.ignore!(0.8)
    standard_read(Research::ModifiedTask[task: @task], Api::V1::MetataskRepresenter)
  end

  api :DELETE, '/tasks/:id', 'Hide the task from the student\'s dashboard'
  description <<-EOS
    Hides the Task from the student's dashboard
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:hide, current_api_user, @task)
    @task.hide.save!
    respond_with @task, represent_with: Api::V1::MetataskRepresenter,
                 responder: ResponderWithPutPatchDeleteContent
  end

  protected

  def get_task
    @task = ::Tasks::Models::Task.preload(
      :research_study_brains,
      task_steps: [:tasked, :page]
    ).find(params[:id])
  end

  def populate_placeholders
    Tasks::PopulatePlaceholderSteps[task: @task]
  end

end
