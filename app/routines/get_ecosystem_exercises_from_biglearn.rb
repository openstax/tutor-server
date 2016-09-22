# Returns Content::Exercises corresponding to a Biglearn query
class GetEcosystemExercisesFromBiglearn

  lev_routine express_output: :ecosystem_exercises

  uses_routine FilterExcludedExercises, as: :filter
  uses_routine GetHistory, as: :get_history
  uses_routine ChooseExercises, as: :choose

  MAX_ATTEMPTS = 3

  protected

  def exec(ecosystem:, role:, pools:, count:, difficulty: 0.5, allow_repetitions: false)
    biglearn_pools = pools.map{ |pl| OpenStax::Biglearn::Api::Pool.new(uuid: pl.uuid) }

    course = role.student.try!(:course)

    admin_excluded_pool_uuid = Settings::Exercises.excluded_pool_uuid
    admin_excluded_pool = OpenStax::Biglearn::Api::Pool.new(uuid: admin_excluded_pool_uuid) \
      unless admin_excluded_pool_uuid.blank?

    course_excluded_pool_uuid = course.try!(:biglearn_excluded_pool_uuid)
    course_excluded_pool = OpenStax::Biglearn::Api::Pool.new(uuid: course_excluded_pool_uuid) \
      unless course_excluded_pool_uuid.nil?

    pool_exclusions = []
    pool_exclusions << { pool: admin_excluded_pool, ignore_versions: false } \
      unless admin_excluded_pool.nil?
    pool_exclusions << { pool: course_excluded_pool, ignore_versions: true } \
      unless course_excluded_pool.nil?

    attempts = 0
    begin
      urls = OpenStax::Biglearn::Api.get_projection_exercises(
        role:              role,
        pools:             biglearn_pools,
        pool_exclusions:   pool_exclusions,
        count:             count,
        difficulty:        difficulty,
        allow_repetitions: allow_repetitions
      )
      numbers = urls.map{ |url| url.chomp('/').split('/').last.split('@').first }
    rescue StandardError => exception
      # Our communication issues turned out to be nginx configuration issues (keepalive_timeout)
      # Still, it's a nice safeguard to have, in case AWS has some trouble,
      # since this Biglearn request may be blocking a student's work
      if (attempts += 1) < MAX_ATTEMPTS
        retry
      else
        pool_exercises = pools.flat_map(&:exercises)
        candidate_exercises = run(:filter, exercises: pool_exercises,
                                           course: course).outputs.exercises
        history = run(:get_history, roles: role, type: :all).outputs.history[role]
        chosen_exercises = run(:choose, exercises: candidate_exercises, count: count,
                                        history: history, allow_repeats: allow_repetitions)
                              .outputs.exercises
        numbers = chosen_exercises.map(&:number).uniq

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

    biglearn_count = numbers.size

    Rails.logger.warn do
      "Biglearn returned less exercises than requested. Pools: #{pools.map(&:uuid)}. Role: #{
        role.id}. Requested: #{count}. Got: #{biglearn_count}. Exercise numbers: #{numbers}."
     end if biglearn_count < count

    exercises = ecosystem.exercises_by_numbers(numbers)
    fatal_error(code: :missing_local_exercises,
                message: "Biglearn returned more exercises than were " +
                         "present locally. [Pools: #{biglearn_pools.map(&:uuid)}, " +
                         "Role: #{role.id}, Requested: #{count}, " +
                         "Got (Biglearn): #{biglearn_count}, " +
                         "Got (local): #{exercises.size}, " +
                         "Exercise numbers: #{numbers}]") \
      if exercises.size < biglearn_count

    outputs[:ecosystem_exercises] = exercises
    outputs[:exercise_numbers] = numbers
  end

end
