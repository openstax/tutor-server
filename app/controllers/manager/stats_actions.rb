module Manager::StatsActions
  def self.included(base)
    base.class_attribute :course_url_proc
  end

  def courses
    @courses = CourseProfile::Models::Course.where(is_preview: false).preload(
      teachers: { role: { role_user: :profile } },
      periods_with_deleted: :latest_enrollments_with_deleted
    ).order(:name).to_a
    @total_students = @courses.map do |course|
      course.periods_with_deleted.map do |period|
        period.latest_enrollments_with_deleted.length
      end.reduce(0, :+)
    end.reduce(0, :+)
    @course_url_proc = course_url_proc

    render 'manager/stats/courses'
  end

  def excluded_exercises
    excluded_exercises = ExportExerciseExclusions.call.outputs
    @excluded_exercises_by_course = excluded_exercises.by_course
    @excluded_exercises_by_exercise = excluded_exercises.by_exercise

    render 'manager/stats/excluded_exercises'
  end

  def excluded_exercises_to_csv
    by_course = params.fetch(:export).fetch(:by).include? "course"
    by_exercise = params.fetch(:export).fetch(:by).include? "exercise"

    unless by_course || by_exercise
      flash[:alert] = "You must select at least one of two options to export"
      redirect_to admin_stats_excluded_exercises_path and return
    end

    ExportExerciseExclusions.perform_later(
      upload_by_course_to_owncloud: by_course, upload_by_exercise_to_owncloud: by_exercise
    )
    flash[:success] = "The export should be available in a few minutes in ownCloud."
    redirect_to admin_stats_excluded_exercises_path
  end

  def concept_coach
    cc_tasks = Tasks::Models::ConceptCoachTask
      .joins(role: {student: :course})
      .where(role: {student: {course: {is_preview: false}}})
      .preload([{page: {chapter: {book: {chapters: :pages}}}}, {role: :profile}])
      .to_a

    @cc_stats = {
      books: cc_tasks.group_by{ |cc| cc.page.chapter.book.title }
                     .map do |book_title, book_cc_tasks|
        candidate_books = book_cc_tasks.map{ |cc| cc.page.chapter.book }.uniq
        latest_book = candidate_books.max_by(&:version)

        {
          title: book_title,
          chapters: book_cc_tasks.group_by{ |cc| cc.page.chapter.title }
                                 .map do |chapter_title, chapter_cc_tasks|
            latest_chapter = latest_book.chapters.find{ |ch| ch.title == chapter_title }
            chapter_number = latest_chapter.try(:number)

            {
              title: chapter_title,
              number: chapter_number,
              pages: chapter_cc_tasks.group_by{ |cc| cc.page.title }
                                     .map do |page_title, page_cc_tasks|
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
    students = cc_tasks.map{ |cc_task| cc_task.role.profile }.uniq.length
    tasks = cc_tasks.map(&:task)
    total = tasks.length
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
