class OpenStax::Biglearn::V1::FakeClient

  def initialize(biglearn_configuration)
    @fake_store = biglearn_configuration.fake_store
  end

  #
  # API methods
  #

  def add_exercises(exercises)
    return [] if exercises.empty?

    # Iterate through the exercises, storing each in the store,
    # overwriting any with the same ID

    exercise_key_to_exercise_map = {}
    [exercises].flatten.each do |exercise|
      exercise_key = "exercises/#{exercise.question_id}"
      exercise_key_to_exercise_map[exercise_key] = exercise
    end

    exercise_keys = exercise_key_to_exercise_map.keys

    exercise_key_to_version_json_map = store.read_multi(*exercise_keys)

    exercise_keys.each do |exercise_key|
      exercise = exercise_key_to_exercise_map[exercise_key]
      version_json = exercise_key_to_version_json_map[exercise_key]
      version_hash = JSON.parse(version_json || '{}')
      version_hash[exercise.version.to_s] = exercise.tags
      store.write(exercise_key, version_hash.to_json)
    end

    [{'message' => 'Question tags saved.'}]
  end

  def add_pools(pools)
    # Add the given pools to the store, overwriting any with the same UUID

    pools.map do |pool|
      pool.uuid ||= SecureRandom.uuid
      json = pool.exercises.map do |ex|
        { question_id: ex.question_id.to_s, version: ex.version }
      end.to_json
      store.write "pools/#{pool.uuid}", json
      pool.uuid
    end
  end

  def combine_pools(pools)
    # Combine the given pools into one

    pool_keys = pools.map{ |pl| "pools/#{pl.uuid}" }
    questions = store.read_multi(*pool_keys).values.flatten.uniq
    uuid = SecureRandom.uuid

    store.write("pools/#{uuid}", questions)

    uuid
  end

  def get_projection_exercises(role:, pools:, pool_exclusions:,
                               count:, difficulty:, allow_repetitions:)
    # Get the exercises in the pools
    pool_keys = pools.map{ |pl| "pools/#{pl.uuid}" }
    pool_questions = store.read_multi(*pool_keys).values.flat_map{ |json| JSON.parse(json) }.uniq

    unless pool_exclusions.empty?
      excluded_pools_to_keys_map = {}
      pool_exclusions.each do |hash|
        pl = hash[:pool]
        excluded_pools_to_keys_map[pl] = "pools/#{pl.uuid}"
      end
      excluded_pool_keys = excluded_pools_to_keys_map.values
      excluded_key_to_json_map = store.read_multi(*excluded_pool_keys)
      pool_exclusions.each_with_index do |pool_exclusion, index|
        excluded_pool = pool_exclusion[:pool]
        ignore_versions = pool_exclusion[:ignore_versions]
        excluded_pool_key = excluded_pools_to_keys_map[excluded_pool]
        excluded_json = excluded_key_to_json_map[excluded_pool_key]
        excluded_questions = JSON.parse excluded_json

        if ignore_versions
          excluded_question_ids = excluded_questions.map{ |question| question['question_id'] }
          pool_questions = pool_questions.reject do |pool_question|
            pool_question['question_id'].in? excluded_question_ids
          end
        else
          pool_questions = pool_questions - excluded_questions
        end
      end
    end

    question_ids = pool_questions.map{ |question| question['question_id'] }

    # Limit the results to the desired number
    results = question_ids.first(count)

    # If we didn't get as many as requested and repetitions are allowed,
    # pad the results, repeat the matches until we have enough, making
    # sure to clip at the desired count in case we go over.
    while (allow_repetitions && results.length < count && question_ids.any?)
      results += question_ids.first(count - results.length)
    end

    results
  end

  def get_clues(roles:, pools:, cache_for: 'ignored', force_cache_miss: 'ignored')
    # The fake client CLUe results are completely random
    pools.each_with_object({}) do |pool, hash|
      aggregate = rand(0.0..1.0)
      confidence_left  = [aggregate - 0.1, 0.0].max
      confidence_right = [aggregate + 0.1, 1.0].min
      level = aggregate >= 0.8 ? 'high' : (aggregate >= 0.3 ? 'medium' : 'low')
      confidence = ['good', 'bad'].sample
      samples = 6
      threshold = 'above'
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

  def store
    @fake_store
  end

end
