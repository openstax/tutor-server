module CourseGuideMethods

  private

  def get_completed_tasked_exercises_from_task_steps(task_steps)
    tasked_exercise_ids = task_steps.flatten.select{ |ts| ts.exercise? && ts.completed? }
                                            .collect{ |ts| ts.tasked_id }
    Tasks::Models::TaskedExercise.where(id: tasked_exercise_ids)
                                 .preload(
      [{task_step: {task: {taskings: :role}}},
       {exercise: {page: :chapter}}]
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

  def get_clue(tasked_exercises, pages)
    roles = tasked_exercises.collect{ |ts| ts.task_step.task.taskings.collect{ |tg| tg.role } }
                            .flatten
    OpenStax::Biglearn::V1.get_clue(roles: roles, pages: pages)
  end

  def compile_pages(page_groupings)
    page_groupings.collect do |page, tasked_exercises|
      practices = completed_practices(tasked_exercises)
      clue = get_clue(tasked_exercises, page)

      {
        title: page.title,
        book_location: page.book_location,
        questions_answered_count: tasked_exercises.count,
        clue: clue,
        practice_count: practices.count,
        page_ids: [page.id]
      }
    end.sort_by{ |pg| pg[:book_location] }
  end

  def compile_chapters(tasked_exercises, ecosystems_map)
    group_tasked_exercises_by_chapters(tasked_exercises, ecosystems_map)
      .collect do |chapter, page_groupings|

      page_hashes = compile_pages(page_groupings)
      tasked_exercises = page_groupings.values.flatten
      practices = completed_practices(tasked_exercises)
      clue = get_clue(tasked_exercises, page_groupings.collect{|pg, te| pg})

      {
        title: chapter.title,
        book_location: chapter.book_location,
        questions_answered_count: tasked_exercises.count,
        clue: clue,
        practice_count: practices.count,
        page_ids: page_hashes.collect{|pp| pp[:page_ids]}.flatten,
        children: page_hashes
      }
    end.sort_by{ |ch| ch[:book_location] }
  end

  def compile_course_guide(task_steps, course)
    current_ecosystem = GetCourseEcosystem[course: course]
    ecosystems_map = GetCourseEcosystemsMap[course: course]
    tasked_exercises = get_completed_tasked_exercises_from_task_steps(task_steps)
    chapters = compile_chapters(tasked_exercises, ecosystems_map)

    {
      title: current_ecosystem.books.first.title,
      page_ids: chapters.collect{ |cc| cc[:page_ids] }.flatten,
      children: chapters
    }
  end

end
