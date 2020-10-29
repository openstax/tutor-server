class FindOrCreatePracticeWorstTopicsTask
  include FindOrCreatePracticeTaskRoutine

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine Tasks::FetchPracticeWorstAreasExercises, as: :fetch_practice_worst_areas_exercises
  uses_routine TaskExercise, as: :task_exercise

  protected

  def setup(**args)
    @task_type = :practice_worst_topics
    @ecosystem = run(:get_course_ecosystem, course: @course).outputs.ecosystem
  end

  def add_task_steps
    exercises = run(
      :fetch_practice_worst_areas_exercises, student: @role.course_member
    ).outputs.exercises

    fatal_error(
      code: :no_exercises,
      message: "No exercises available to build the Practice Widget." +
               " [Course: #{@course.id} - Role: #{@role.id}" +
               " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
    ) if exercises.empty?

    # It's probably fine to give students slightly bigger practice tasks
    # if that means they get whole MPQ questions
    remaining = FindOrCreatePracticeTaskRoutine::NUM_EXERCISES
    exercises = exercises.select do |exercise|
      (remaining > 0).tap { remaining -= exercise.number_of_questions }
    end

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
