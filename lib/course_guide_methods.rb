module CourseGuideMethods

  private

  def get_completed_tasked_exercises_from_task_steps(task_steps)
    tasked_exercise_ids = task_steps.flatten.select{ |ts| ts.exercise? && ts.completed? }
                                            .collect{ |ts| ts.tasked_id }
    Tasks::Models::TaskedExercise.where(id: tasked_exercise_ids).preload(
      [{task_step: {task: {taskings: :role}}}, {exercise: {page: :chapter}}]
    )
  end

  def group_tasked_exercises_by_pages(tasked_exercises, ecosystems_map)
    exercises = tasked_exercises.collect do |tasked_exercise|
      content_exercise = tasked_exercise.exercise
      strategy = ::Content::Strategies::Direct::Exercise.new(content_exercise)
      ::Content::Exercise.new(strategy: strategy)
    end
    exercise_pages = ecosystems_map.map_exercises_to_pages(exercises: exercises)

    tasked_exercises.each_with_index.each_with_object({}) do |(tasked_exercise, index), hash|
      page = exercise_pages[index]
      hash[page] ||= []
      hash[page] << tasked_exercise
    end
  end

  def group_tasked_exercises_by_chapters(tasked_exercises, ecosystems_map)
    page_grouping = group_tasked_exercises_by_pages(tasked_exercises, ecosystems_map)
    page_grouping.each_with_object({}) do |(page, exercises), hash|
      hash[page.chapter] = (hash[page.chapter] || {}).merge(page => exercises)
    end
  end

  def completed_practices(tasked_exercises)
    tasked_exercises.collect{ |te| te.task_step.task }.select do |task|
      task.completed? && (task.chapter_practice? || task.page_practice? || task.mixed_practice?)
    end.uniq
  end

  def get_los_and_aplos(tasked_exercises)
    [tasked_exercises].flatten.collect{ |te| te.los + te.aplos }.flatten.uniq
  end

  def get_chapter_clues(sorted_chapter_groupings)
    tasked_exercises = sorted_chapter_groupings.flat_map do |chapter, page_groupings|
      page_groupings.flat_map{ |page, tasked_exercises| tasked_exercises }
    end

    roles = tasked_exercises.flat_map do |te|
      te.task_step.task.taskings.collect{ |tg| tg.role }
    end.uniq

    # Flatten the array of pools so we can send it to Biglearn
    pools = sorted_chapter_groupings.flat_map do |chapter, sorted_page_groupings|
      [chapter.all_exercises_pool] + sorted_page_groupings.collect do |page, tasked_exercises|
        page.all_exercises_pool
      end
    end

    OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools)
  end

  def compile_pages(sorted_page_groupings, clues_map)
    tasked_exercises = sorted_page_groupings.flat_map{ |page, tasked_exercises| tasked_exercises }
    roles = tasked_exercises.flat_map do |te|
      te.task_step.task.taskings.collect{ |tg| tg.role }
    end.uniq

    sorted_page_groupings.each_with_index.collect do |(page, tasked_exercises), index|
      practices = completed_practices(tasked_exercises)

      {
        title: page.title,
        book_location: page.book_location,
        questions_answered_count: tasked_exercises.size,
        clue: clues_map[page.all_exercises_pool.uuid],
        practice_count: practices.size,
        page_ids: [page.id]
      }
    end
  end

  def compile_chapters(tasked_exercises, ecosystems_map)
    chapter_groupings = group_tasked_exercises_by_chapters(tasked_exercises, ecosystems_map)

    sorted_chapter_groupings = chapter_groupings.to_a.collect do |chapter, page_groupings|
      [chapter, page_groupings.to_a.sort_by{ |page, tasked_exercises| page.book_location }]
    end.sort_by{ |chapter, sorted_page_groupings| chapter.book_location }

    clues_map = get_chapter_clues(sorted_chapter_groupings)

    sorted_chapter_groupings.each_with_index.collect do |(chapter, sorted_page_groupings), index|

      page_hashes = compile_pages(sorted_page_groupings, clues_map)
      tasked_exercises = sorted_page_groupings.flat_map do |page, tasked_exercises|
        tasked_exercises
      end
      practices = completed_practices(tasked_exercises)

      {
        title: chapter.title,
        book_location: chapter.book_location,
        questions_answered_count: tasked_exercises.size,
        clue: clues_map[chapter.all_exercises_pool.uuid],
        practice_count: practices.size,
        page_ids: page_hashes.collect{|pp| pp[:page_ids]}.flatten,
        children: page_hashes
      }
    end
  end

  def compile_course_guide(task_steps, course)
    current_ecosystem = GetCourseEcosystem[course: course]
    ecosystems_map = GetCourseEcosystemsMap[course: course]
    tasked_exercises = get_completed_tasked_exercises_from_task_steps(task_steps)
    chapters = compile_chapters(tasked_exercises, ecosystems_map)

    {
      # Assuming only 1 book per ecosystem
      title: current_ecosystem.books.first.title,
      page_ids: chapters.collect{ |cc| cc[:page_ids] }.flatten,
      children: chapters
    }
  end

end
