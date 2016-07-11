module OpenStax::Biglearn::V1
  class LocalQueryClient

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
                                 count:, difficulty: nil, allow_repetitions:)
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
        tasked_exercises = tasked_exercises_by(pool: pool, roles: roles)
        responses = tasked_exercises.map{|te| te.is_correct? ? 1.0 : 0.0}

        local_clue = LocalClue.new(responses: responses)

        hash[pool.uuid] = {
          value: local_clue.aggregate,
          value_interpretation: local_clue.level.to_s,
          confidence_interval: [
            local_clue.left,
            local_clue.right
          ],
          confidence_interval_interpretation: local_clue.confidence.to_s,
          sample_size: responses.size,
          sample_size_interpretation: local_clue.threshold.to_s,
          unique_learner_count: roles.size
        }
      end
    end

    def tasked_exercises_by(pool:, roles:)
      Tasks::Models::TaskedExercise
        .joins{task_step.task.taskings}
        .where{task_step.task.taskings.entity_role_id.in roles.map(&:id)}
        .where{content_exercise_id.in pool.exercise_ids}
    end
  end

end
