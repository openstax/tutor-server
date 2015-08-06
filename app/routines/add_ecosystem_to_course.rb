class AddEcosystemToCourse
  lev_routine

  uses_routine CourseEcosystem::AddEcosystemToCourse,
               translations: { outputs: {type: :verbatim} }

  protected

  def exec(course:, ecosystem:)
    run(CourseEcosystem::AddEcosystemToCourse, course: course, ecosystem: ecosystem)
  end
end
