class CreatePracticeSpecificTopicsTask
  include CreatePracticeTaskRoutine

  protected

  def setup(page_ids:)
    @task_type = :page_practice
    @pages = Content::Models::Page.where(id: page_ids).preload(:ecosystem)
    ecosystems = @pages.map(&:ecosystem).uniq
    fatal_error(
      code: :different_ecosystems, message: 'All page_ids given must belong to the same Ecosystem'
    ) if ecosystems.size > 1
    @ecosystem = ecosystems.first

    fatal_error(code: :invalid_page_ids) unless @course.ecosystems.include?(@ecosystem)
  end

  def add_task_steps
    # Need at least 1 placeholder per page so we know where to place the exercise steps
    @pages.each do |page|
      task_step = Tasks::Models::TaskStep.new(
        tasked: Tasks::Models::TaskedPlaceholder.exercise_type.new,
        group_type: :personalized_group,
        is_core: true,
        page: page
      )

      @task.task_steps << task_step
    end

    after_transaction do
      # This needs to happen after the transaction where the task is created
      # so it can be sent to Biglearn in the background
      outputs.task = Tasks::PopulatePlaceholderSteps.call(
        task: @task, skip_unready: true
      ).outputs.task

      nonfatal_error(
        code: :no_exercises,
        message: "No exercises were returned from Biglearn to build the Practice Widget." +
                 " [Course: #{@course.id} - Role: #{@role.id}" +
                 " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
      ) if outputs.task.pes_are_assigned && outputs.task.task_steps.empty?
    end
  end
end
