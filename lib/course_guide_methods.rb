module CourseGuideMethods

  private

  def self.included(base)
    base.lev_routine express_output: :course_guide
    base.uses_routine GetHistory, as: :get_history
    base.uses_routine GetCourseEcosystem, as: :get_course_ecosystem
    base.uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map
  end

  def get_clues_by_pool_uuids(roles, mapped_core_pages_by_chapter, type)
    # Flatten the array of pools at the end so we can send it to Biglearn
    pools = mapped_core_pages_by_chapter.flat_map do |chapter, mapped_core_pages|
      [chapter.all_exercises_pool] + mapped_core_pages.map(&:all_exercises_pool)
    end

    OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools)
  end

  def get_page_guides(mapped_core_pages,
                      clues_by_pool_uuids,
                      practice_counts_by_mapped_core_page_ids,
                      completed_exercises_count_by_mapped_core_page_ids)
    mapped_core_pages.map do |mapped_core_page|
      page_id = mapped_core_page.id

      {
        title: mapped_core_page.title,
        book_location: mapped_core_page.book_location,
        questions_answered_count: completed_exercises_count_by_mapped_core_page_ids[page_id],
        clue: clues_by_pool_uuids[mapped_core_page.all_exercises_pool.uuid],
        practice_count: practice_counts_by_mapped_core_page_ids[page_id],
        page_ids: [page_id]
      }
    end
  end

  def get_chapter_guides(mapped_core_pages_by_chapter,
                         clues_by_pool_uuids,
                         practice_counts_by_mapped_core_page_ids,
                         completed_exercises_count_by_mapped_core_page_ids)

    mapped_core_pages_by_chapter.map do |chapter, mapped_core_pages|
      mapped_core_page_ids = mapped_core_pages.map(&:id).sort

      {
        title: chapter.title,
        book_location: chapter.book_location,
        questions_answered_count: completed_exercises_count_by_mapped_core_page_ids
                                    .values_at(*mapped_core_page_ids).reduce(:+),
        clue: clues_by_pool_uuids[chapter.all_exercises_pool.uuid],
        practice_count: practice_counts_by_mapped_core_page_ids.values_at(*mapped_core_page_ids)
                                                               .reduce(:+),
        page_ids: mapped_core_page_ids,
        children: get_page_guides(mapped_core_pages,
                                  clues_by_pool_uuids,
                                  practice_counts_by_mapped_core_page_ids,
                                  completed_exercises_count_by_mapped_core_page_ids)
      }
    end
  end

  def get_role_guides(roles, history, ecosystems_map, type)
    roles = [roles].flatten
    relevant_role_histories = history.values_at(*roles)

    all_core_page_ids = relevant_role_histories.map do |role_history|
      # Exclude unopened tasks in history
      opens_ats = role_history.opens_ats
      open_task_indices = opens_ats.each_index.select do |index|
        opens_ats[index] <= Time.now
      end
      role_history.core_page_ids.values_at(*open_task_indices)
    end.flatten

    all_core_pages_by_id = {}
    Content::Models::Page.where(id: all_core_page_ids).each do |content_page|
      all_core_pages_by_id[content_page.id] = Content::Page.new strategy: content_page.wrap
    end

    all_core_pages = all_core_pages_by_id.values

    # Map pages in tasks to the newest ecosystem
    page_map = ecosystems_map.map_pages_to_pages(pages: all_core_pages)

    mapped_core_page_ids = page_map.values.flatten.map(&:id).uniq.sort
    mapped_core_pages_by_chapter = Content::Models::Page
      .where(id: mapped_core_page_ids)
      .preload([:all_exercises_pool, {chapter: :all_exercises_pool}])
      .reject{ |page| page.all_exercises_pool.empty? } # Skip intro pages
      .group_by(&:chapter)
    mapped_core_page_ids_with_exercises = mapped_core_pages_by_chapter.values.flatten.map(&:id)

    clues_by_pool_uuids = get_clues_by_pool_uuids(roles, mapped_core_pages_by_chapter, type)

    practice_counts_by_mapped_core_page_ids = Hash.new{ |hash, key| hash[key] = 0 }
    relevant_role_histories.each do |role_history|
      task_types = role_history.task_types
      practice_task_indices = task_types.each_index.select do |index|
        task_types[index] == :practice
      end
      practice_core_page_ids = role_history.core_page_ids.values_at(*practice_task_indices)
      practice_core_page_ids.each do |core_page_ids|
        core_page_ids.each do |core_page_id|
          core_page = all_core_pages_by_id[core_page_id]
          mapped_core_page_id = page_map[core_page].id

          practice_counts_by_mapped_core_page_ids[mapped_core_page_id] += 1
        end
      end
    end

    role_ids = roles.map(&:id)
    completed_exercises_count_by_core_page_ids = Tasks::Models::TaskedExercise
      .joins([:exercise, {task_step: {task: :taskings}}])
      .where(task_step: {task: {taskings: {entity_role_id: role_ids}}})
      .where{task_step.first_completed_at != nil}
      .group(exercise: :content_page_id)
      .count
    completed_exercises_count_by_mapped_core_page_ids = Hash.new{ |hash, key| hash[key] = 0 }
    completed_exercises_count_by_core_page_ids.each do |core_page_id, completed_exercises_count|
      core_page = all_core_pages_by_id[core_page_id]
      mapped_page_id = page_map[core_page].id

      completed_exercises_count_by_mapped_core_page_ids[mapped_page_id] = completed_exercises_count
    end

    # Assuming only 1 book per ecosystem
    book = mapped_core_pages_by_chapter.keys.first.book

    {
      title: book.title,
      page_ids: mapped_core_page_ids_with_exercises,
      children: get_chapter_guides(mapped_core_pages_by_chapter,
                                   clues_by_pool_uuids,
                                   practice_counts_by_mapped_core_page_ids,
                                   completed_exercises_count_by_mapped_core_page_ids)
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
