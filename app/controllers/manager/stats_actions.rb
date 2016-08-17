module Manager::StatsActions
  def self.included(base)
    base.class_attribute :course_url_proc
  end

  def courses
    @courses = Entity::Course.joins(:profile).preload(
      [
        :profile, { teachers: { role: { role_user: :profile } },
                    periods_with_deleted: :latest_enrollments_with_deleted }
      ]
    ).order{ profile.name }.to_a
    @total_students = @courses.map do |course|
      course.periods_with_deleted.map do |period|
        period.latest_enrollments_with_deleted.length
      end.reduce(0, :+)
    end.reduce(0, :+)
    @course_url_proc = course_url_proc

    render 'manager/stats/courses'
  end

  def excluded_exercises
    @excluded_exercises = CourseContent::Models::ExcludedExercise.preload(
      course: [
        :profile, { teachers: { role: { role_user: :profile } } }
      ]
    )
    @exercise_links = {}
    @excluded_exercises.each do |excluded_exercise|
      number = excluded_exercise.exercise_number
      @exercise_links[number] = OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
    end
    @course_url_proc = course_url_proc

    render 'manager/stats/excluded_exercises'
  end

  def concept_coach
    cc_tasks = Tasks::Models::ConceptCoachTask.preload([
      {page: {chapter: {book: {chapters: :pages}}}}, {task: {taskings: {role: :profile}}}
    ]).to_a

    @cc_stats = {
      books: cc_tasks.group_by{ |cc| cc.page.chapter.book.title }.map do |book_title, book_cc_tasks|
        candidate_books = book_cc_tasks.map{ |cc| cc.page.chapter.book }.uniq
        latest_book = candidate_books.max_by(&:version)

        {
          title: book_title,
          chapters: book_cc_tasks.group_by{ |cc| cc.page.chapter.title }.map do |chapter_title,
                                                                                 chapter_cc_tasks|
            latest_chapter = latest_book.chapters.find{ |ch| ch.title == chapter_title }
            chapter_number = latest_chapter.try(:number)

            {
              title: chapter_title,
              number: chapter_number,
              pages: chapter_cc_tasks.group_by{ |cc| cc.page.title }.map do |page_title,
                                                                             page_cc_tasks|
                latest_page = latest_chapter.pages.find{ |pg| pg.title == page_title }
                page_number = latest_page.try(:number)

                {
                  title: page_title,
                  number: page_number
                }.merge(get_cc_task_stats(page_cc_tasks))
              end.sort_by{ |pg| pg[:number] || Float::INFINITY }
            }.merge(get_cc_task_stats(chapter_cc_tasks))
          end.sort_by{ |ch| ch[:number] || Float::INFINITY }
        }.merge(get_cc_task_stats(book_cc_tasks))
      end.sort_by{ |bk| bk[:title] }
    }.merge(get_cc_task_stats(cc_tasks))

    render 'manager/stats/concept_coach'
  end

  protected

  def get_cc_task_stats(cc_tasks)
    tasks = cc_tasks.map(&:task)
    total = tasks.length
    students = tasks.flat_map{ |task| task.taskings.map{ |tg| tg.role.profile } }.uniq.length
    in_progress = tasks.select(&:in_progress?).length
    completed = tasks.select(&:completed?).length
    not_started = total - (in_progress + completed)
    exercises = tasks.map(&:exercise_steps_count).reduce(0, :+)
    completed_exercises = tasks.map(&:completed_exercise_steps_count).reduce(0, :+)
    incomplete_exercises = exercises - completed_exercises
    correct_exercises = tasks.map(&:correct_exercise_steps_count).reduce(0, :+)

    {
      tasks: total,
      students: students,
      not_started: not_started,
      in_progress: in_progress,
      completed: completed,
      exercises: exercises,
      incomplete_exercises: incomplete_exercises,
      completed_exercises: completed_exercises,
      correct_exercises: correct_exercises
    }
  end
end
