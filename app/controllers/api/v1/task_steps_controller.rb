class Api::V1::TaskStepsController < Api::V1::ApiController

  around_action :with_task_step_and_tasked, except: :show
  before_action :fetch_step, only: :show
  before_action :error_if_student_and_needs_to_pay
  before_action :populate_placeholders_if_needed, only: :show

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
    standard_read(
      Research::ModifiedTasked[tasked: @tasked],
      Api::V1::TaskedRepresenterMapper.representer_for(@tasked),
      false,
      include_content: true
    )
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/steps/:step_id', 'Updates the specified TaskStep'
  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @tasked)
    OSU::AccessPolicy.require_action_allowed!(:mark_completed, current_api_user, @tasked)

    consume!(@tasked, represent_with: Api::V1::TaskedRepresenterMapper.representer_for(@tasked))
    @tasked.save

    result = MarkTaskStepCompleted.call(task_step: @task_step, lock_task: true)
    raise(ActiveRecord::Rollback) if render_api_errors(result.errors)

    respond_with(
      @tasked,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::TaskedRepresenterMapper.representer_for(@tasked),
      user_options: { include_content: true }
    )
  end

  protected

  def fetch_step
    @task_step = ::Tasks::Models::TaskStep.find(params[:id])
    @tasked = Research::ModifiedTasked[tasked: @task_step.tasked]
  end

  def with_task_step_and_tasked
    Tasks::Models::TaskStep.transaction do
      # The explicit listing of the tables to lock is required here
      # because we want to lock the tables in exactly this order to avoid deadlocks
      @task = Tasks::Models::Task
        .joins(:task_steps)
        .lock('FOR NO KEY UPDATE OF "tasks_tasks", "tasks_task_steps"')
        .preload(:research_study_brains, task_steps: :tasked)\
        .find_by(task_steps: { id: params[:id] })

      return render_api_errors(:no_exercises, :not_found) if @task.nil?


      @task_step = @task.task_steps.to_a.find { |task_step| task_step.id == params[:id].to_i }
      @tasked = Research::ModifiedTasked[tasked: @task_step.tasked]
      yield
    end
  end

  def populate_placeholders_if_needed
    return unless @tasked.is_a? Tasks::Models::TaskedPlaceholder

    # Task already locked in around_action
    Tasks::PopulatePlaceholderSteps[task: @task, lock_task: false]

    @tasked.reload
  end


end
