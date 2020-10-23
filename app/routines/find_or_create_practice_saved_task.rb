class FindOrCreatePracticeSavedTask
  include FindOrCreatePracticeTaskRoutine

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine TaskExercise, as: :task_exercise

  protected

  def setup(**args)
    @exercise_ids = available_questions(args[:question_ids]).pluck(:content_exercise_id)
    @task_type = :practice_saved
    @ecosystem = run(:get_course_ecosystem, course: @course).outputs.ecosystem
  end

  def available_questions(question_ids)
    @role.practice_questions.where(id: question_ids).select(&:available?)
  end

  def add_task_steps
    exercises = Content::Models::Exercise.where(id: @exercise_ids)

    fatal_error(
      code: :no_exercises,
      message: "No exercises available to build the Saved Practice." +
               " [Course: #{@course.id} - Role: #{@role.id}" +
               " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
    ) if exercises.empty?

    exercises = FilterExcludedExercises.call(
      exercises: exercises,
      role: @role,
      additional_excluded_numbers: [],
      current_time: Time.current
    ).outputs.exercises

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
