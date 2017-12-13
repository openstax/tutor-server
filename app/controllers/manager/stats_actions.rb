module Manager::StatsActions
  def self.included(base)
    base.class_attribute :course_url_proc
  end

  def courses
    @courses = CourseProfile::Models::Course.where(is_preview: false).preload(
      teachers: { role: { role_user: :profile } },
      periods: :latest_enrollments
    ).order(:name).to_a

    @total_students = @courses.map do |course|
      course.periods.map do |period|
        period.latest_enrollments.length
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
      flash[:alert] = "You must select at least one of the two options to export"
      redirect_to admin_stats_excluded_exercises_path
      return
    end

    ExportExerciseExclusions.perform_later(
      upload_by_course: by_course, upload_by_exercise: by_exercise
    )
    flash[:success] = "The export is being created and will be uploaded to Box when ready"
    redirect_to admin_stats_excluded_exercises_path
  end
end
