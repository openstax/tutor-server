class Api::V1::TaskStepsController < Api::V1::ApiController

  around_action :with_task_step_and_tasked
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
    @task = Research::ModifiedTaskForDisplay[task: @task]
    @task_step = @task.task_steps.to_a.find { |task_step| task_step.id == params[:id].to_i }
    @tasked = @task_step.tasked
    standard_read(@tasked, Api::V1::TaskedRepresenterMapper.representer_for(@tasked))
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/steps/:step_id', 'Updates the specified TaskStep'
  def update
    # We only update last_completed_at if the task_step is already completed
    update_task_step(mark_completed: @task_step.completed?)
  end

  ###############################################################
  # completed
  ###############################################################

  api :PUT, '/steps/:step_id/completed',
            'Marks the specified TaskStep as completed (if applicable)'
  description <<-EOS
    Marks a task step as complete, which may create or modify other steps.
    The entire task is returned so the FE can update as needed.

    #{json_schema(Api::V1::TaskRepresenter, include: :readable)}
  EOS
  def completed
    update_task_step(mark_completed: true)
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
      @tasked = @task_step.tasked

      yield
    end
  end

  def populate_placeholders_if_needed
    return unless @tasked.is_a? Tasks::Models::TaskedPlaceholder

    # Task already locked in around_action
    Tasks::PopulatePlaceholderSteps[task: @task, lock_task: false]

    @tasked.reload
  end

  def update_task_step(mark_completed:)
    ScoutHelper.ignore!(0.8)

    @tasked = Research::ModifiedTaskedForUpdate[tasked: @tasked]

    OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @tasked)
    OSU::AccessPolicy.require_action_allowed!(:mark_completed, current_api_user, @tasked) \
      if mark_completed

    consume!(@tasked, represent_with: Api::V1::TaskedRepresenterMapper.representer_for(@tasked))
    @tasked.save

    if mark_completed
      # Task already locked in around_action
      result = MarkTaskStepCompleted.call(task_step: @task_step, lock_task: false)
      raise(ActiveRecord::Rollback) if render_api_errors(result.errors)
    end

    raise(ActiveRecord::Rollback) if render_api_errors(@tasked.errors)

    @task = Research::ModifiedTaskForDisplay[task: @task]
    respond_with(
      @task,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::TaskRepresenter
    )
  end

end
