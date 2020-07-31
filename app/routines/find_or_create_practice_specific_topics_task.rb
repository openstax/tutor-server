class FindOrCreatePracticeSpecificTopicsTask
  include FindOrCreatePracticeTaskRoutine

  protected

  def setup(page_ids:)
    @task_type = :page_practice
    pages = Content::Models::Page.where(id: page_ids).order(:id).preload(:ecosystem)
    ecosystems = pages.map(&:ecosystem).uniq
    fatal_error(
      code: :different_ecosystems, message: 'All page_ids given must belong to the same Ecosystem'
    ) if ecosystems.size > 1
    @ecosystem = ecosystems.first
    @pages = pages.reject { |page| page.practice_widget_exercise_ids.empty? }
    @page_ids = @pages.map(&:id)

    fatal_error(code: :invalid_page_ids) unless @course.ecosystems.include?(@ecosystem)
  end

  def add_task_steps
    # Need at least 1 placeholder per page so we know where to place the exercise steps
    # But we don't really need to keep track of more pages than we can handle
    pages = @pages.shuffle
    num_pages = pages.size

    FindOrCreatePracticeTaskRoutine::NUM_EXERCISES.times.map do |index|
      task_step = Tasks::Models::TaskStep.new(
        tasked: Tasks::Models::TaskedPlaceholder.exercise_type.new,
        group_type: :personalized_group,
        is_core: true,
        page: pages[index % num_pages]
      )

      @task.task_steps << task_step
    end

    @task.save!

    outputs.task = Tasks::PopulatePlaceholderSteps.call(task: @task).outputs.task

    nonfatal_error(
      code: :no_exercises,
      message: "No exercises available to build the Practice Widget." +
               " [Course: #{@course.id} - Role: #{@role.id}" +
               " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
    ) if outputs.task.pes_are_assigned && outputs.task.task_steps.empty?
  end
end
