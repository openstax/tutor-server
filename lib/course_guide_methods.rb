module CourseGuideMethods

  private

  def map_tasked_exercise_exercise_ids_to_latest_pages(tasked_exercises, course)
    exercises = tasked_exercises.map do |tasked_exercise|
      content_exercise = tasked_exercise.exercise
      strategy = ::Content::Strategies::Direct::Exercise.new(content_exercise)
      ::Content::Exercise.new(strategy: strategy)
    end.uniq

    ecosystems_map = GetCourseEcosystemsMap[course: course]
    exercise_map = ecosystems_map.map_exercises_to_pages(exercises: exercises)

    exercise_id_map = {}
    exercises.each{ |exercise| exercise_id_map[exercise.id] = exercise_map[exercise] }

    exercise_id_map
  end

  def group_tasked_exercises_by_pages(tasked_exercises, exercise_id_to_page_map)
    tasked_exercises.group_by do |tasked_exercise|
      exercise_id_to_page_map[tasked_exercise.content_exercise_id]
    end
  end

  def group_tasked_exercises_by_chapters(tasked_exercises, exercise_id_to_page_map)
    chapter_grouping = {}

    page_grouping = group_tasked_exercises_by_pages(tasked_exercises, exercise_id_to_page_map)
    page_grouping.each do |page, exercises|
      chapter_grouping[page.chapter] = (chapter_grouping[page.chapter] || {})
                                         .merge(page => exercises)
    end

    chapter_grouping
  end

  def completed_practices(tasked_exercises)
    tasked_exercises.map{ |te| te.task_step.task }.select do |task|
      task.completed? && (task.chapter_practice? || task.page_practice? || task.mixed_practice?)
    end.uniq
  end

  def get_chapter_clues(sorted_chapter_groupings, type)
    tasked_exercises = sorted_chapter_groupings.flat_map do |chapter, page_groupings|
      page_groupings.flat_map{ |page, tasked_exercises| tasked_exercises }
    end

    # Flatten the array of pools so we can send it to Biglearn
    pools = sorted_chapter_groupings.flat_map do |chapter, sorted_page_groupings|
      [chapter.all_exercises_pool] + sorted_page_groupings.map do |page, tasked_exercises|
        page.all_exercises_pool
      end
    end

    roles = tasked_exercises.flat_map do |te|
      te.task_step.task.taskings.map(&:role)
    end.uniq

    OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools)
  end

  def compile_pages(sorted_page_groupings, clues_map)
    tasked_exercises = sorted_page_groupings.flat_map(&:second)

    sorted_page_groupings.each_with_index.map do |(page, tasked_exercises), index|
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

  def compile_chapters(tasked_exercises, exercise_id_to_page_map, type)
    chapter_groupings = group_tasked_exercises_by_chapters(tasked_exercises,
                                                           exercise_id_to_page_map)

    sorted_chapter_groupings = chapter_groupings.to_a.map do |chapter, page_groupings|
      [chapter, page_groupings.to_a.sort_by{ |page, tasked_exercises| page.book_location }]
    end.sort_by{ |chapter, sorted_page_groupings| chapter.book_location }

    clues_map = get_chapter_clues(sorted_chapter_groupings, type)

    sorted_chapter_groupings.each_with_index.map do |(chapter, sorted_page_groupings), index|

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
        page_ids: page_hashes.flat_map{|pp| pp[:page_ids]},
        children: page_hashes
      }
    end
  end

  def compile_course_guide(course, tasked_exercises, exercise_id_to_page_map, type = :student)
    current_ecosystem = GetCourseEcosystem[course: course]
    chapters = compile_chapters(tasked_exercises, exercise_id_to_page_map, type)

    {
      # Assuming only 1 book per ecosystem
      title: current_ecosystem.books.first.title,
      page_ids: chapters.flat_map{ |cc| cc[:page_ids] },
      children: chapters
    }
  end

end
