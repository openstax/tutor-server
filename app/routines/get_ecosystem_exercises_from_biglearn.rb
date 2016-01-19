# Returns Content::Exercises corresponding to a Biglearn query
class GetEcosystemExercisesFromBiglearn
  lev_routine express_output: :ecosystem_exercises

  MAX_ATTEMPTS = 3

  protected

  def exec(ecosystem:, role:, pools:, count:, difficulty: 0.5, allow_repetitions: true)
    biglearn_pools = pools.collect{ |pl| OpenStax::Biglearn::V1::Pool.new(uuid: pl.uuid) }

    attempts = 0
    begin
      urls = OpenStax::Biglearn::V1.get_projection_exercises(
        role:              role,
        pools:             biglearn_pools,
        count:             count,
        difficulty:        difficulty,
        allow_repetitions: allow_repetitions
      )
      numbers = urls.collect{ |url| url.chomp('/').split('/').last.split('@').first }
    rescue OAuth2::Error => exception
      if (attempts += 1) < MAX_ATTEMPTS
        retry
      else
        numbers = pools.flat_map{ |pl| pl.exercises.map(&:number) }.uniq.sample(count)

        ExceptionNotifier.notify_exception(
          exception,
          data: {
            error_id: "%06d" % SecureRandom.random_number(10**6),
            message: 'Maximum number of retries exceeded while trying to communicate with Biglearn. Using a random local problem instead.',
            attempts: attempts,
            cause: exception
          },
          sections: %w(data request session environment backtrace)
        )
      end
    end

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
