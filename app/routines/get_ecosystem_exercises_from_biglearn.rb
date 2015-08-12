# Returns Content::Exercises corresponding to a Biglearn query
class GetEcosystemExercisesFromBiglearn
  lev_routine express_output: :ecosystem_exercises

  protected

  def exec(ecosystem:, role:, pools:, count:, difficulty: 0.5, allow_repetitions: true)
    biglearn_pools = pools.collect{ |pl| OpenStax::Biglearn::V1::Pool.new(uuid: pl.uuid) }

    numbers = OpenStax::Biglearn::V1.get_projection_exercises(
      role:              role,
      pools:             biglearn_pools,
      count:             count,
      difficulty:        difficulty,
      allow_repetitions: allow_repetitions
    )

    exercises = ecosystem.exercises_by_numbers(numbers)
    fatal_error(code: :missing_local_exercises,
                message: "Biglearn returned more exercises for the practice widget than were " +
                         "present locally. [pools: #{biglearn_pools.collect{|pl| pl.uuid}}, " +
                         "role: #{role.id}, requested: #{count}, " +
                         "from biglearn: #{numbers.count}, " +
                         "local found: #{exercises.size}] biglearn question ids: #{numbers}") \
      if exercises.size != numbers.count

    outputs[:ecosystem_exercises] = exercises
  end
end
