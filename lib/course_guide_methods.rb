module CourseGuideMethods

  private

  def get_completed_tasked_exercises_from_task_steps(task_steps)
    tasked_exercise_ids = task_steps.flatten.select{ |ts| ts.exercise? && ts.completed? }
                                            .collect{ |ts| ts.tasked_id }
    Tasks::Models::TaskedExercise.where(id: tasked_exercise_ids).eager_load(
      [{task_step: {task: {taskings: :role}}},
       {exercise: {tags: {page_tags: {page: {book_part: :book}}}}}]
    )
  end

  def group_tasked_exercises_by_pages_from_book(tasked_exercises, book)
    tasked_exercises.each_with_object({}) do |te, hash|
      pages = te.exercise.tags.collect do |tt|
        tt.page_tags.collect{ |pt| pt.page }
      end.flatten.uniq

      pages.each do |page|
        next unless page.book_part.book == book
        hash[page] ||= []
        hash[page] << te
      end
    end
  end

  def group_tasked_exercises_by_chapters_from_book(tasked_exercises, book)
    tasked_exercises.each_with_object({}) do |te, hash|
      chapters = te.exercise.tags.collect do |tt|
        tt.page_tags.collect{ |pt| pt.page.book_part }
      end.flatten.uniq

      chapters.each do |chapter|
        next unless chapter.book == book
        hash[chapter] ||= []
        hash[chapter] << te
      end
    end
  end

  def filter_tasked_exercises_by_book(tasked_exercises, book)
    tasked_exercises.select do |te|
      te.exercise.tags.any? do |tt|
        tt.page_tags.any?{ |pt| pt.page.book_part.book == book }
      end
    end
  end

  def completed_practices(tasked_exercises)
    tasked_exercises.collect{ |te| te.task_step.task }.select do |task|
      task.completed? && (task.chapter_practice? || task.page_practice? || task.mixed_practice?)
    end.uniq
  end

  def get_lo_and_aplos(tasked_exercises)
    [tasked_exercises].flatten.collect{ |te| te.los + te.aplos }.flatten.uniq
  end

  def get_clue(tasked_exercises)
    tags = get_lo_and_aplos(tasked_exercises)
    roles = tasked_exercises.collect{ |ts| ts.task_step.task.taskings.collect{ |tg| tg.role } }
                            .flatten
    OpenStax::Biglearn::V1.get_clue(roles: roles, tags: tags)
  end

  def compile_pages(tasked_exercises, book)
    group_tasked_exercises_by_pages_from_book(tasked_exercises, book)
      .collect do |page, tasked_exercises|

      practices = completed_practices(tasked_exercises)
      clue = get_clue(tasked_exercises)

      {
        title: page.title,
        chapter_section: page.chapter_section,
        questions_answered_count: tasked_exercises.count,
        clue: clue,
        practice_count: practices.count,
        page_ids: [page.id]
      }
    end.sort_by{ |pg| pg[:chapter_section] }
  end

  def compile_chapters(tasked_exercises, book)
    group_tasked_exercises_by_chapters_from_book(tasked_exercises, book)
      .collect do |chapter, tasked_exercises|

      pages = compile_pages(tasked_exercises, book)
      practices = completed_practices(tasked_exercises)
      clue = get_clue(tasked_exercises)

      {
        title: chapter.title,
        chapter_section: chapter.chapter_section,
        questions_answered_count: tasked_exercises.count,
        clue: clue,
        practice_count: practices.count,
        page_ids: pages.collect{|pp| pp[:page_ids]}.flatten,
        children: pages
      }
    end.sort_by{ |ch| ch[:chapter_section] }
  end

  def compile_guide(task_steps, book)
    tasked_exercises = get_completed_tasked_exercises_from_task_steps(task_steps)
    filtered_tasked_exercises = filter_tasked_exercises_by_book(tasked_exercises, book)
    chapters = compile_chapters(filtered_tasked_exercises, book)

    {
      title: book.root_book_part.title,
      page_ids: chapters.collect{ |cc| cc[:page_ids] }.flatten,
      children: chapters
    }
  end

end
