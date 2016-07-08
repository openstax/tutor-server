class OpenStax::Biglearn::V1::LocalQueryClient

  def initialize(write_client)
    raise "Write client must be set" if write_client.nil?
    @write_client = write_client
  end

  def name
    :local_query
  end

  #
  # Delegate all outgoing messages to the write client; implement other queries locally.
  # This lets us maintain a constant stream of data to the real Biglearn while we perform
  # maintenance on the real system's more complex queries
  #

  def add_exercises(exercises)
    @write_client.add_exercises(exercises)
  end

  def add_pools(pools)
    @write_client.add_pools(pools)
  end

  def combine_pools(pools)
    @write_client.combine_pools(pools)
  end

  def get_projection_exercises(role:, pools:, pool_exclusions:,
                               count:, difficulty:, allow_repetitions:)
    pool_exercises = pools.flat_map(&:exercises)
    course = role.student.try(:course)

    excluded_exercise_numbers = []
    pool_exclusions.each do |hash|
      excluded_pool = hash[:pool]
      excluded_exercise_numbers += excluded_pool.exercises.map(&:number)
    end
    excluded_exercise_numbers.uniq!

    filtered_exercises = FilterExcludedExercises[
      exercises: pool_exercises, course: course,
      additional_excluded_numbers: excluded_exercise_numbers
    ]

    history = GetHistory[roles: role, type: :all][role]

    chosen_exercises = ChooseExercises[
      exercises: filtered_exercises, count: count,
      history: history, allow_repeats: allow_repetitions,
      randomize_exercises: true, randomize_order: true
    ]

    chosen_exercises.map(&:url)
  end

  def get_clues(roles:, pools:, force_cache_miss: 'ignored')
    pools.each_with_object({}) do |pool, hash|
      aggregate = 0.5
      confidence_left  = 0.0
      confidence_right = 1.0
      level = aggregate >= 0.8 ? 'high' : (aggregate >= 0.3 ? 'medium' : 'low')
      confidence = 'bad'
      samples = 6
      threshold = 'below'
      unique_learner_count = roles.size

      hash[pool.uuid] = {
        value: aggregate,
        value_interpretation: level,
        confidence_interval: [
          confidence_left,
          confidence_right
        ],
        confidence_interval_interpretation: confidence,
        sample_size: samples,
        sample_size_interpretation: threshold,
        unique_learner_count: unique_learner_count
      }
    end
  end

end
