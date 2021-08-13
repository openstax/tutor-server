class Api::V1::TaskStepsController < Api::V1::ApiController
  include Ratings::Concerns::RatingJobs

  # This around_action puts all actions except show inside a database transaction
  around_action :with_task_step_and_tasked, except: :show
  before_action :fetch_step, only: :show
  before_action :error_if_student_and_needs_to_pay

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
      ::Research::ModifiedTasked[tasked: @tasked],
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
    OSU::AccessPolicy.require_action_allowed! :update, current_api_user, @tasked

    if @tasked.exercise?
      previous_free_response = @tasked.free_response
      previous_answer_id = @tasked.answer_id
    end

    consume!(
      @tasked,
      represent_with: Api::V1::TaskedRepresenterMapper.representer_for(@tasked),
      user_options: { include_content: true } # needed so representer will consume free_response
    )

    if @tasked.exercise?
      # The frontend can optionally set the attempt_number
      # so we validate that they are seeing the correct number of attempts left (no change)
      if @tasked.attempt_number_changed?
        # We didn't get the expected attempt number
        # Render an error message
        render_api_errors(
          code: 'invalid_attempt_number',
          message: 'This question is already in progress in another tab or window;' +
                   ' reload this page to continue.'
        )

        raise ActiveRecord::Rollback
      end
      last_completed_at = @task_step.last_completed_at

      if last_completed_at.nil?
        unless @tasked.last_graded_at.nil?
          # First attempt, but was already graded
          # Clear the grade to allow the student to actually answer it
          @tasked.last_graded_at = nil
          @tasked.grader_points = nil
          @tasked.grader_comments = nil
        end

        @tasked.attempt_number = 1
      elsif @tasked.multiple_attempts? && (
        @tasked.free_response_changed? || @tasked.answer_id_changed?
      )
        # Second attempt, with multiple attempts enabled
        # Record the previous attempt
        previous_attempt = Tasks::Models::PreviousAttempt.new(
          tasked_exercise: @tasked,
          number: @tasked.attempt_number,
          attempted_at: last_completed_at,
          free_response: previous_free_response,
          answer_id: previous_answer_id
        )
        @tasked.attempt_number += 1
        @tasked.previous_attempts << previous_attempt
        raise(ActiveRecord::Rollback) if render_api_errors(previous_attempt.errors)
      end
    end

    @tasked.save
    raise(ActiveRecord::Rollback) if render_api_errors(@tasked.errors)

    result = MarkTaskStepCompleted.call(task_step: @task_step, lock_task: true)
    raise(ActiveRecord::Rollback) if render_api_errors(result.errors)

    respond_with(
      @tasked,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::TaskedRepresenterMapper.representer_for(@tasked),
      user_options: { include_content: true }
    )
  end

  ###############################################################
  # grade
  ###############################################################

  api :PUT, '/steps/:step_id/grade', 'Grades the specified TaskStep'
  description <<-EOS
    #{json_schema(Api::V1::Tasks::TaskedExerciseGradingRepresenter, include: :writeable)}
  EOS
  def grade
    OSU::AccessPolicy.require_action_allowed!(:grade, current_api_user, @tasked)

    consume! @tasked, represent_with: Api::V1::Tasks::TaskedExerciseGradingRepresenter

    # The frontend can optionally set the attempt_number
    # so we validate that they are seeing the correct number of attempts left (no change)
    if @tasked.attempt_number_changed?
      # We didn't get the expected attempt number
      # Render an error message
      render_api_errors(
        code: 'invalid_attempt_number_graded',
        message: 'A new response has been submitted, please reload your browser.'
      )

      raise ActiveRecord::Rollback
    end

    @tasked.last_graded_at = Time.current
    @tasked.save
    raise(ActiveRecord::Rollback) if render_api_errors(@tasked.errors)

    task = @tasked.task_step.task
    role = task.taskings.first&.role
    perform_rating_jobs_later(
      task: task,
      role: role,
      period: role.course_member.period,
      event: :grade
    ) unless role.nil?

    task.update_caches_later

    respond_with(
      @tasked,
      represent_with: Api::V1::Tasks::TaskedExerciseGradingRepresenter,
      responder: ResponderWithPutPatchDeleteContent
    )
  end

  protected

  def fetch_step
    @task_step = ::Tasks::Models::TaskStep.find(params[:id])
    @tasked = ::Research::ModifiedTasked[tasked: @task_step.tasked]
  end

  def with_task_step_and_tasked
    ::Tasks::Models::TaskStep.transaction do
      # The explicit listing of the tables to lock is required here
      # because we want to lock the tables in exactly this order to avoid deadlocks
      @task = Tasks::Models::Task
        .joins(:task_steps)
        .lock('FOR NO KEY UPDATE OF "tasks_tasks", "tasks_task_steps"')
        .preload(:research_study_brains)
        .find_by(task_steps: { id: params[:id] })

      return render_api_errors(:no_exercises, :not_found) if @task.nil?

      @task_step = @task.task_steps.to_a.find { |task_step| task_step.id == params[:id].to_i }
      @tasked = ::Research::ModifiedTasked[tasked: @task_step.tasked]
      yield
    end
  end
end
