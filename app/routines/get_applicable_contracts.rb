class GetApplicableContracts

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
      # get contracts
      # if no contracts add general_terms and privacy_policy
      # if contracts add them unless blanket signed
    end

    contracts.compact.uniq
  end
end
