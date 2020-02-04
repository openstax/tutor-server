class CreatePracticeSpecificTopicsTask
  include CreatePracticeTaskRoutine

  uses_routine GetEcosystemFromIds, as: :get_ecosystem

  protected

  def setup(page_ids: nil, chapter_ids: nil)
    @task_type = if page_ids.present?
      chapter_ids.present? ? :mixed_practice : :page_practice
    else
      chapter_ids.present? ? :chapter_practice : fatal_error(
        code: :page_ids_and_chapter_ids_blank,
    	  message: 'You must specify at least one of page_id or chapter_id'
      )
    end

    course_ecosystems = @course.ecosystems.map { |eco| Content::Ecosystem.new strategy: eco.wrap }
    @ecosystem = run(:get_ecosystem, page_ids: page_ids, chapter_ids: chapter_ids).outputs.ecosystem
    fatal_error(code: :invalid_page_ids_or_chapter_ids) \
      unless course_ecosystems.include?(@ecosystem)

    # Gather relevant chapters and pages
    chapters = @ecosystem.chapters_by_ids(chapter_ids)
    @pages = @ecosystem.pages_by_ids(page_ids) + chapters.map(&:pages).flatten.uniq
  end

  def add_task_steps
    # Need at least 1 placeholder per page so we know where to place the exercise steps
    @pages.each do |page|
      task_step = Tasks::Models::TaskStep.new(
        tasked: Tasks::Models::TaskedPlaceholder.exercise_type.new,
        group_type: :personalized_group,
        is_core: true,
        page: page.to_model
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
