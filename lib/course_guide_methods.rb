module CourseGuideMethods

  private

  def self.included(base)
    base.lev_routine express_output: :course_guide
    base.uses_routine GetHistory, as: :get_history
    base.uses_routine GetCourseEcosystem, as: :get_course_ecosystem
    base.uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map
  end

  def get_clues_by_book_container_uuids(roles, mapped_relevant_pages_by_chapter, type)
    book_containers = mapped_relevant_pages_by_chapter.flat_map do |chapter, mapped_relevant_pages|
      [chapter] + mapped_relevant_pages
    end

    if roles.size == 1
      # Student guide
      OpenStax::Biglearn::Api.fetch_learner_clues(book_containers: book_containers,
                                                  students: roles.first.student)
    else
      # Teacher guide
      periods = roles.map(&:student).map(&:period).uniq
      raise "Cannot call Biglearn with multiple periods" if periods.size != 1

      OpenStax::Biglearn::Api.fetch_teacher_clues(period: periods.first,
                                                  book_containers: book_containers)
    end
  end

  def get_page_guides(mapped_relevant_pages,
                      clues_by_pool_uuids,
                      practice_counts_by_mapped_relevant_page_ids,
                      completed_exercises_count_by_mapped_relevant_page_ids)
    mapped_relevant_pages.map do |mapped_relevant_page|
      page_id = mapped_relevant_page.id

      {
        title: mapped_relevant_page.title,
        book_location: mapped_relevant_page.book_location,
        questions_answered_count: completed_exercises_count_by_mapped_relevant_page_ids[page_id],
        clue: clues_by_pool_uuids[mapped_relevant_page.all_exercises_pool.uuid],
        practice_count: practice_counts_by_mapped_relevant_page_ids[page_id],
        page_ids: [page_id]
      }
    end
  end

  def get_chapter_guides(mapped_relevant_pages_by_chapter,
                         clues_by_pool_uuids,
                         practice_counts_by_mapped_relevant_page_ids,
                         completed_exercises_count_by_mapped_relevant_page_ids)

    mapped_relevant_pages_by_chapter.map do |chapter, mapped_relevant_pages|
      mapped_relevant_page_ids = mapped_relevant_pages.map(&:id)

      {
        title: chapter.title,
        book_location: chapter.book_location,
        questions_answered_count: completed_exercises_count_by_mapped_relevant_page_ids
                                    .values_at(*mapped_relevant_page_ids).reduce(0, :+),
        clue: clues_by_pool_uuids[chapter.all_exercises_pool.uuid],
        practice_count: practice_counts_by_mapped_relevant_page_ids
                          .values_at(*mapped_relevant_page_ids).reduce(0, :+),
        page_ids: mapped_relevant_page_ids,
        children: get_page_guides(mapped_relevant_pages,
                                  clues_by_pool_uuids,
                                  practice_counts_by_mapped_relevant_page_ids,
                                  completed_exercises_count_by_mapped_relevant_page_ids)
      }
    end
  end

  def get_role_guides(roles, history, ecosystems_map, type)
    roles = [roles].flatten
    return [] if roles.size == 0

    relevant_role_histories = history.values_at(*roles)

    all_core_page_ids = relevant_role_histories.map do |role_history|
      # Exclude unopened tasks in history
      opens_ats = role_history.opens_ats
      open_task_indices = opens_ats.each_index.select do |index|
        opens_ats[index].nil? || opens_ats[index] <= Time.current
      end
      role_history.core_page_ids.values_at(*open_task_indices)
    end.flatten

    role_ids = roles.map(&:id)
    completed_exercises_count_by_page_ids = Tasks::Models::TaskedExercise
      .joins([:exercise, {task_step: {task: :taskings}}])
      .where(task_step: {task: {taskings: {entity_role_id: role_ids}}})
      .where{task_step.first_completed_at != nil}
      .group(exercise: :content_page_id)
      .count
    all_worked_page_ids = completed_exercises_count_by_page_ids.keys

    all_relevant_page_ids = (all_core_page_ids + all_worked_page_ids).uniq

    all_relevant_pages_by_id = {}
    Content::Models::Page.where(id: all_relevant_page_ids).select(:id).each do |content_page|
      all_relevant_pages_by_id[content_page.id] = Content::Page.new strategy: content_page.wrap
    end

    all_relevant_pages = all_relevant_pages_by_id.values

    # Map pages in tasks to the newest ecosystem
    page_map = ecosystems_map.map_pages_to_pages(pages: all_relevant_pages)

    all_mapped_page_ids = page_map.values.flatten.map(&:id)
    mapped_relevant_pages_by_chapter = Content::Models::Page
      .joins(:all_exercises_pool)
      .where(id: all_mapped_page_ids)
      .where{all_exercises_pool.content_exercise_ids != '[]'} # Skip intro pages
      .select([Content::Models::Page.arel_table[:id],
               Content::Models::Page.arel_table[:title],
               Content::Models::Page.arel_table[:book_location],
               Content::Models::Page.arel_table[:content_all_exercises_pool_id],
               Content::Models::Page.arel_table[:content_chapter_id]])
      .preload([:all_exercises_pool, {chapter: :all_exercises_pool}])
      .sort_by(&:book_location)
      .group_by(&:chapter)
    mapped_relevant_page_ids_with_exercises = \
      mapped_relevant_pages_by_chapter.values.flatten.map(&:id)

    clues_by_book_container_uuids = get_clues_by_book_container_uuids(
      roles, mapped_relevant_pages_by_chapter, type
    )

    practice_counts_by_mapped_relevant_page_ids = Hash.new{ |hash, key| hash[key] = 0 }
    relevant_role_histories.each do |role_history|
      task_types = role_history.task_types
      practice_task_indices = task_types.each_index.select do |index|
        task_types[index] == :practice
      end
      practice_core_page_ids = role_history.core_page_ids.values_at(*practice_task_indices)
      practice_core_page_ids.each do |core_page_ids|
        core_page_ids.each do |core_page_id|
          relevant_page = all_relevant_pages_by_id[core_page_id]
          mapped_relevant_page_id = page_map[relevant_page].id

          practice_counts_by_mapped_relevant_page_ids[mapped_relevant_page_id] += 1
        end
      end
    end


    completed_exercises_count_by_mapped_relevant_page_ids = Hash.new{ |hash, key| hash[key] = 0 }
    completed_exercises_count_by_page_ids.each do |page_id, completed_exercises_count|
      relevant_page = all_relevant_pages_by_id[page_id]
      mapped_relevant_page_id = page_map[relevant_page].id

      completed_exercises_count_by_mapped_relevant_page_ids[mapped_relevant_page_id] += \
        completed_exercises_count
    end

    # Assuming only 1 book per ecosystem
    book = ecosystems_map.to_ecosystem.books.first

    {
      title: book.title,
      page_ids: mapped_relevant_page_ids_with_exercises,
      children: get_chapter_guides(mapped_relevant_pages_by_chapter,
                                   clues_by_book_container_uuids,
                                   practice_counts_by_mapped_relevant_page_ids,
                                   completed_exercises_count_by_mapped_relevant_page_ids)
    }
  end

  protected

  def exec(role:)
    outputs.course_guide = get_course_guide(role)
  end

  def get_history_for_roles(roles)
    run(:get_history, roles: roles).outputs.history
  end

  def get_course_ecosystems_map(course)
    run(:get_course_ecosystems_map, course: course).outputs.ecosystems_map
  end

  def get_period_guide(period, period_roles, history, ecosystems_map, type)
    { period_id: period.id }.merge(
      get_role_guides(period_roles, history, ecosystems_map, type)
    )
  end

end
