# Returns Ecosystem::Exercises corresponding to a Biglearn query
class GetEcosystemExercisesFromBiglearn
  lev_routine express_output: :ecosystem_exercises

  protected

  def exec(role:, pools:, count:, difficulty: 0.5, allow_repetitions: true)
    # If we have more than one pool, we must first combine them all into a single pool
    pool = [pools].flatten.size > 1 ? OpenStax::Biglearn::V1.combine_pools(pools) : pools.first

    urls = OpenStax::Biglearn::V1.get_projection_exercises(
      role:              role,
      pool:              pool,
      count:             count,
      difficulty:        difficulty,
      allow_repetitions: allow_repetitions
    )

    numbers = urls.collect do |url|
      uri = Addressable::URI.parse(url)
      uri.path.chomp('/').split('/').last.split('@').first
    end

    exercises = ecosystem.exercises_by_numbers(numbers)
    fatal_error(code: :missing_local_exercises,
                message: "Biglearn returned more exercises for the practice widget than " +
                         "were present locally. [pool: #{pool.uuid}, " +
                         "role: #{role.id}, requested: #{count}, "
                         "from biglearn: #{numbers.count}, " +
                         "local found: #{exercises.size}] biglearn numbers: #{numbers}") \
      if exercises.size != numbers.count

    outputs[:ecosystem_exercises] = exercises
  end
end
