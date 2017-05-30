class CreatePracticeWorstTopicsTask

  include CreatePracticeTaskRoutine

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem

  protected

  def setup(**args)
    @task_type = :practice_worst_topics

    @ecosystem = run(:get_course_ecosystem, course: @course).outputs.ecosystem
  end

  def add_task_steps
    exercises = OpenStax::Biglearn::Api.fetch_practice_worst_areas_exercises(student: @role.student)
                                       .first(CreatePracticeTaskRoutine::NUM_BIGLEARN_EXERCISES)

    fatal_error(
      code: :no_exercises,
      message: "No exercises were returned from Biglearn to build the Practice Widget." +
               " [Course: #{@course.id} - Role: #{@role.id}" +
               " - Task Type: #{@task_type} - Ecosystem: #{@ecosystem.title}]"
    ) if exercises.empty?

    # Add the exercises as task steps
    exercises.each do |exercise|
      TaskExercise.call(exercise: exercise, task: @task) do |step|
        step.group_type = :personalized_group
        step.add_related_content(exercise.page.related_content)
      end
    end.tap { @task.update_attribute :pes_are_assigned, true }
  end

end
