# Returns Content::Exercises corresponding to a Biglearn query
class GetEcosystemExercisesFromBiglearn
  lev_routine express_output: :ecosystem_exercises

  MAX_ATTEMPTS = 3

  protected

  def exec(ecosystem:, role:, pools:, count:, difficulty: 0.5, allow_repetitions: true)
    biglearn_pools = pools.collect{ |pl| OpenStax::Biglearn::V1::Pool.new(uuid: pl.uuid) }

    course_profile = role.student.try(:course).try(:profile)

    # TODO: Add admin exclusion pool here (later)
    excluded_pools = [course_profile.try(:biglearn_excluded_pool_uuid)].compact.map do |uuid|
      OpenStax::Biglearn::V1::Pool.new(uuid: uuid)
    end

    pool_exclusions = excluded_pools.map{ |pool| { pool: pool, ignore_versions: true } }

    attempts = 0
    begin
      urls = OpenStax::Biglearn::V1.get_projection_exercises(
        role:              role,
        pools:             biglearn_pools,
        pool_exclusions:   pool_exclusions,
        count:             count,
        difficulty:        difficulty,
        allow_repetitions: allow_repetitions
      )
      numbers = urls.map{ |url| url.chomp('/').split('/').last.split('@').first }
    rescue OAuth2::Error => exception
      # Our communication issues turned out to be nginx configuration issues (keepalive_timeout)
      # Still, it's a nice safeguard to have, in case AWS has some trouble,
      # since this Biglearn request may be blocking a student's work
      if (attempts += 1) < MAX_ATTEMPTS
        retry
      else
        numbers = pools.flat_map{ |pl| pl.exercises.map(&:number) }.uniq.sample(count)

        ExceptionNotifier.notify_exception(
          exception,
          data: {
            error_id: "%06d" % SecureRandom.random_number(10**6),
            message: 'Maximum number of retries exceeded while trying to communicate with Biglearn. Using random local problems instead.',
            attempts: attempts,
            cause: exception
          },
          sections: %w(data request session environment backtrace)
        )
      end
    end

    exercises = ecosystem.exercises_by_numbers(numbers)
    fatal_error(code: :missing_local_exercises,
                message: "Biglearn returned more exercises than were " +
                         "present locally. [pools: #{biglearn_pools.collect{|pl| pl.uuid}}, " +
                         "role: #{role.id}, requested: #{count}, " +
                         "from biglearn: #{numbers.size}, " +
                         "local found: #{exercises.size}] biglearn question ids: #{numbers}") \
      if exercises.size < numbers.size

    outputs[:ecosystem_exercises] = exercises
  end
end
