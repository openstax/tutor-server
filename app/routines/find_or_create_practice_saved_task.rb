class FindOrCreatePracticeSavedTask
  include FindOrCreatePracticeTaskRoutine

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine TaskExercise, as: :task_exercise

  protected

  def setup(**args)
    @exercise_uuids = get_exercise_uuids(args[:question_ids])
    @task_type = :practice_saved
    @ecosystem = run(:get_course_ecosystem, course: @course).outputs.ecosystem
  end

  def get_exercise_uuids(question_ids)
    @role.practice_questions.where(id: question_ids).map(&:exercise_uuid)
  end

  def add_task_steps
    exercises =
      Content::Models::Exercise.select('DISTINCT ON ("content_exercises"."number") "content_exercises".*')
        .joins(book: :ecosystem)
        .where(book: { content_ecosystem_id: @course.ecosystems.map(&:id) }, uuid: @exercise_uuids)
        .order(:number, version: :desc)

    exercises = FilterExcludedExercises.call(
      exercises: exercises,
      role: @role,
      additional_excluded_numbers: [],
      current_time: Time.current,
      profile_ids: @course.related_teacher_profile_ids
    ).outputs.exercises

    fatal_error(
      code: :no_exercises,
      message: "No exercises available to build the Saved Practice." +
               " [Course: #{@course.id} - Role: #{@role.id}" +
               " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
    ) if exercises.empty?

    # Add the exercises as task steps
    exercises.each do |exercise|
      run(
        :task_exercise,
        exercise: exercise,
        task: @task,
        group_type: :personalized_group,
        is_core: true
      )
    end.tap { @task.pes_are_assigned = true }
  end
end
