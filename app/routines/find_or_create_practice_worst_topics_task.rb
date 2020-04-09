class FindOrCreatePracticeWorstTopicsTask
  include FindOrCreatePracticeTaskRoutine

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem
  uses_routine TaskExercise, as: :task_exercise
  uses_routine TranslateBiglearnSpyInfo, as: :translate_biglearn_spy_info

  protected

  def setup(**args)
    @task_type = :practice_worst_topics

    @ecosystem = run(:get_course_ecosystem, course: @course).outputs.ecosystem

    @page_ids = []
  end

  def add_task_steps
    result = OpenStax::Biglearn::Api.fetch_practice_worst_areas_exercises(
      student: @role.course_member
    )

    fatal_error(
      code: :no_exercises,
      message: "No exercises were returned from Biglearn to build the Practice Widget." +
               " [Course: #{@course.id} - Role: #{@role.id}" +
               " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
    ) if result[:exercises].empty?

    # It's probably fine to give students slightly bigger practice tasks
    # if that means they get whole MPQ questions
    remaining = FindOrCreatePracticeTaskRoutine::NUM_EXERCISES
    exercises = result[:exercises].select do |exercise|
      (remaining > 0).tap { remaining -= exercise.number_of_questions }
    end
    spy_info = run(:translate_biglearn_spy_info, spy_info: result[:spy_info]).outputs.spy_info

    # Add the exercises as task steps
    exercise_spy_info = spy_info.fetch('exercises', {})
    exercises.each do |exercise|
      run(
        :task_exercise,
        exercise: exercise,
        task: @task,
        group_type: :personalized_group,
        is_core: true,
        spy: exercise_spy_info.fetch(exercise.uuid, {})
      )
    end.tap do
      @task.pes_are_assigned = true
      @task.spy = @task.spy.merge spy_info.except('exercises')
    end
  end
end
