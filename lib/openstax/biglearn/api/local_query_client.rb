module OpenStax::Biglearn::Api
  class LocalQueryClient

    def initialize(write_client)
      raise "Write client must be set" if write_client.nil?
      @write_client = write_client
    end

    def name
      @write_client.is_a?(RealClient) ? :local_query_with_real : :local_query_with_fake
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

    def combine_pools(pool_uuids)
      @write_client.combine_pools(pool_uuids)
    end

    def get_projection_exercises(role:, pool_uuids:, pool_exclusions:,
                                 count:, difficulty: nil, allow_repetitions:)
      pool_exercises = Content::Models::Pool.where{uuid.in pool_uuids}.flat_map(&:exercises)
      course = role.student.try(:course)

      excluded_exercise_numbers = Content::Models::Pool.where{
        uuid.in pool_exclusions.map{|pe| pe[:pool].uuid}
      }.flat_map(&:exercises).map(&:number).uniq

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

    def get_clues(roles:, pool_uuids:, force_cache_miss: 'ignored')
      tasked_exercises_by_pool_uuid_and_role = completed_tasked_exercises_by(
        pool_uuids: pool_uuids, roles: roles
      )

      hash = {}
      tasked_exercises_by_pool_uuid_and_role.each do |uuid, tasked_exercises_by_role|
        tasked_exercises = tasked_exercises_by_role.values.flatten
        responses = tasked_exercises.map{ |te| te.is_correct? ? 1.0 : 0.0 }

        local_clue = LocalClue.new(responses: responses)

        hash[uuid] = {
          value: local_clue.aggregate,
          value_interpretation: local_clue.level.to_s,
          confidence_interval: [
            local_clue.left,
            local_clue.right
          ],
          confidence_interval_interpretation: local_clue.confidence.to_s,
          sample_size: responses.size,
          sample_size_interpretation: local_clue.threshold.to_s,
          unique_learner_count: tasked_exercises_by_role.keys.size
        }
      end
      hash
    end

    # This method returns completed tasked exercises grouped by their pool uuid
    # for the array of pool_uuids and the array of roles given
    def completed_tasked_exercises_by(pool_uuids:, roles:)
      content_pools = Content::Models::Pool
        .where(uuid: pool_uuids)
        .select{[uuid, content_exercise_ids]}

      if content_pools.size < pool_uuids.size
        missing_uuids = pool_uuids - content_pools.map(&:uuid)

        raise "Could not find content pools for uuids: [#{missing_uuids.join(', ')}]"
      end

      all_pool_exercise_ids = content_pools.flat_map(&:content_exercise_ids)
      pool_exercises_by_id = Content::Models::Exercise.where(id: all_pool_exercise_ids)
                                                      .select([:id, :number])
                                                      .index_by(&:id)

      pool_uuids_by_exercise_number = Hash.new{ |hash, key| hash[key] = [] }
      content_pools.each do |pool|
        exercise_ids = pool.content_exercise_ids
        exercise_ids.each do |exercise_id|
          exercise_number = pool_exercises_by_id[exercise_id].number
          pool_uuids_by_exercise_number[exercise_number] << pool.uuid
        end
      end

      all_pool_exercise_numbers = pool_uuids_by_exercise_number.keys

      tasked_exercises_by_pool_uuid_and_role_id = {}
      pool_uuids.each do |pool_uuid|
        tasked_exercises_by_pool_uuid_and_role_id[pool_uuid] = Hash.new do |hash, key|
          hash[key] = []
        end
      end

      Tasks::Models::TaskedExercise
        .joins{[task_step.task.taskings, exercise]}
        .where{task_step.task.taskings.entity_role_id.in roles.map(&:id)}
        .where{task_step.first_completed_at != nil}
        .where{exercise.number.in all_pool_exercise_numbers}
        .select do
          [Tasks::Models::TaskedExercise.arel_table[Arel.star],
           task_step.task.taskings.entity_role_id,
           exercise.number.as(:exercise_number)]
        end.each do |tasked_exercise|
          role_id = tasked_exercise.entity_role_id

          pool_uuids_by_exercise_number[tasked_exercise.exercise_number].each do |pool_uuid|
            tasked_exercises_by_pool_uuid_and_role_id[pool_uuid][role_id] << tasked_exercise
          end
        end

      tasked_exercises_by_pool_uuid_and_role_id
    end
  end

end
