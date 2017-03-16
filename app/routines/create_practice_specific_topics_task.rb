class CreatePracticeSpecificTopicsTask

  include CreatePracticeTaskRoutine

  uses_routine GetEcosystemFromIds, as: :get_ecosystem

  protected

  def setup(course:, role:, page_ids: nil, chapter_ids: nil)
    @task_type = if page_ids.present?
      chapter_ids.present? ? :mixed_practice : :page_practice
    else
      chapter_ids.present? ? :chapter_practice : fatal_error(
        code: :page_ids_and_chapter_ids_blank,
    	  message: 'You must specify at least one of page_id or chapter_id'
      )
    end

    course_ecosystems = course.ecosystems.map { |eco| Content::Ecosystem.new strategy: eco.wrap }
    @ecosystem = run(:get_ecosystem, page_ids: page_ids, chapter_ids: chapter_ids).outputs.ecosystem
    fatal_error(code: :invalid_page_ids_or_chapter_ids) \
      unless course_ecosystems.include?(@ecosystem)

    @course = course

    # Gather relevant chapters and pages
    chapters = @ecosystem.chapters_by_ids(chapter_ids)
    @pages = @ecosystem.pages_by_ids(page_ids) + chapters.map(&:pages).flatten.uniq
  end

  def get_exercises(task:, count:)
    OpenStax::Biglearn::Api.create_update_assignments(
      course: @course, task: task, core_page_ids: @pages.map(&:id), perform_later: false
    )

    OpenStax::Biglearn::Api.fetch_assignment_pes task: task, max_num_exercises: count
  end

end
