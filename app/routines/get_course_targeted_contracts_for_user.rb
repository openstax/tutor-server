class GetCourseTargetedContractsForUser

  lev_routine express_output: :contracts

  uses_routine GetUserCourses,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:)
    run(GetUserCourses, user: user)
    outputs[:contracts] = get_course_contracts(outputs.courses)
  end

  def get_course_contracts(courses)
    contracts = courses.collect do |course|
      targeted_contracts = Legal::Api.targeted_contracts(applicable_to: course) # applicable_to:
    end

    contracts.compact.uniq
  end
end
