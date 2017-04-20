class CreatePracticeWorstTopicsTask

  include CreatePracticeTaskRoutine

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem

  protected

  def setup(course:, role:)
    @task_type = :practice_worst_topics

    @ecosystem = run(:get_course_ecosystem, course: course).outputs.ecosystem

    @role = role
  end

  def get_exercises(task:, count:)
    OpenStax::Biglearn::Api.fetch_practice_worst_areas_exercises(
      student: @role.student, max_num_exercises: count
    )
  end

end
