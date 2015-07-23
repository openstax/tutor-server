module CourseGuideMethods

  private

  def filter_completed_exercise_steps(task_steps)
    task_steps.flatten.select{ |ts| ts.exercise? && ts.completed? }
  end

  def group_task_steps_by_pages_from_book(task_steps, book)
    task_steps.each_with_object({}) do |ts, hash|
      pages = ts.tasked.exercise.tags.collect do |tt|
        tt.page_tags.collect{ |pt| pt.page }
      end.flatten.uniq

      pages.each do |page|
        next unless page.book_part.book == book
        hash[page] ||= []
        hash[page] << ts
      end
    end
  end

  def group_task_steps_by_chapters_from_book(task_steps, book)
    task_steps.each_with_object({}) do |ts, hash|
      chapters = ts.tasked.exercise.tags.collect do |tt|
        tt.page_tags.collect{ |pt| pt.page.book_part }
      end.flatten.uniq

      chapters.each do |chapter|
        next unless chapter.book == book
        hash[chapter] ||= []
        hash[chapter] << ts
      end
    end
  end

  def filter_task_steps_by_book(task_steps, book)
    task_steps.select do |ts|
      ts.tasked.exercise.tags.any? do |tt|
        tt.page_tags.any?{ |pt| pt.page.book_part.book == book }
      end
    end
  end

  def completed_practices(task_steps)
    task_steps.collect(&:task).select do |task|
      task.completed? && (task.chapter_practice? || task.page_practice? || task.mixed_practice?)
    end.uniq
  end

  def get_los(task_steps)
    [task_steps].flatten.collect(&:los).flatten.uniq
  end

  def get_aplos(task_steps)
    [task_steps].flatten.collect(&:aplos).flatten.uniq
  end

  def get_current_level(task_steps)
    tags = get_los(task_steps) + get_aplos(task_steps)
    roles = task_steps.collect{ |ts| ts.task.taskings.collect{ |tg| tg.role } }.flatten
    OpenStax::Biglearn::V1.get_clue(roles: roles, tags: tags)
  end

  def compile_pages(task_steps, book)
    group_task_steps_by_pages_from_book(task_steps, book).collect do |page, task_steps|
      practices = completed_practices(task_steps)

      {
        title: page.title,
        chapter_section: page.chapter_section,
        questions_answered_count: task_steps.count,
        current_level: get_current_level(task_steps),
        practice_count: practices.count,
        page_ids: [page.id]
      }
    end.sort_by{ |pg| pg[:chapter_section] }
  end

  def compile_chapters(task_steps, book)
    group_task_steps_by_chapters_from_book(task_steps, book).collect do |chapter, task_steps|
      pages = compile_pages(task_steps, book)
      practices = completed_practices(task_steps)

      {
        title: chapter.title,
        chapter_section: chapter.chapter_section,
        questions_answered_count: task_steps.count,
        current_level: get_current_level(task_steps),
        practice_count: practices.count,
        page_ids: pages.collect{|pp| pp[:page_ids]}.flatten,
        children: pages
      }
    end.sort_by{ |ch| ch[:chapter_section] }
  end

  def compile_guide(task_steps, book)
    ts = filter_task_steps_by_book(task_steps, book)
    chapters = compile_chapters(ts, book)

    {
      title: book.root_book_part.title,
      page_ids: chapters.collect{ |cc| cc[:page_ids] }.flatten,
      children: chapters
    }
  end

end
