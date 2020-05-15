class ChooseExercises
  # The maximum number of question parts that will be dropped per exercise
  # This corresponds to how many numbers above the given count we need to search
  MAX_DROPPED_QUESTION_PARTS = 4

  INITIAL_GLICKO_MU = 0.0
  INITIAL_GLICKO_PHI = 2.015
  DESIRED_EXPECTED_SCORE = 0.5

  lev_routine express_output: :exercises

  def exec(
    exercises:,
    role:,
    count:,
    already_assigned_exercise_numbers: [],
    randomize_exercises: false,
    randomize_order: false
  )
    already_assigned_exercise_numbers_set = Set.new already_assigned_exercise_numbers

    exercises = exercises.uniq
    exercises = if randomize_exercises
      exercises.shuffle
    else
      page_uuid_by_page_id = Content::Models::Page.where(
        id: exercises.map(&:content_page_id).uniq
      ).pluck(:id, :uuid).to_h
      page_uuids = page_uuid_by_page_id.values

      role_book_parts_by_page_uuid = Ratings::RoleBookPart.where(
        role: role, book_part_uuid: page_uuids
      ).index_by(&:book_part_uuid)

      exercise_book_parts_by_exercise_group_uuid_and_page_uuid = Hash.new do |hash, key|
        hash[key] = {}
      end
      Ratings::ExerciseGroupBookPart.where(
        exercise_group_uuid: exercises.map(&:group_uuid), book_part_uuid: page_uuids
      ).each do |exercise_group_book_part|
        exercise_book_parts_by_exercise_group_uuid_and_page_uuid[
          exercise_group_book_part.exercise_group_uuid
        ][
          exercise_group_book_part.book_part_uuid
        ] = exercise_group_book_part
      end

      exercises.sort_by do |exercise|
        page_uuid = page_uuid_by_page_id[exercise.content_page_id]

        role_book_part = role_book_parts_by_page_uuid[page_uuid] || Ratings::RoleBookPart.new(
          glicko_mu: INITIAL_GLICKO_MU
        )
        exercise_group_book_part = exercise_book_parts_by_exercise_group_uuid_and_page_uuid[
          exercise.group_uuid
        ][
          page_uuid
        ] || Ratings::ExerciseGroupBookPart.new(
          glicko_mu: INITIAL_GLICKO_MU, glicko_phi: INITIAL_GLICKO_PHI
        )

        (
          Ratings::CalculateGAndE.call(
            record: role_book_part, opponents: [ exercise_group_book_part ]
          ).outputs.e_array.first - DESIRED_EXPECTED_SCORE
        ).abs
      end
    end

    new_exercises = exercises.reject do |ex|
      already_assigned_exercise_numbers_set.include?(ex.number)
    end

    outputs.exercises = choose_exercises(new_exercises, exercises, count, randomize_exercises)

    outputs.exercises = outputs.exercises.shuffle if randomize_order
  end

  # https://stackoverflow.com/a/10889840
  # Finds all integer partitions of a number (all sets of integers that add up to that number)
  # with up max_num_ints integers
  def integer_partition(num, max_num_ints = num)
    return [ [] ] if num == 0

    @integer_partitions ||= Hash.new { |hash, key| hash[key] = {} }
    @integer_partitions[num][max_num_ints] ||= [ max_num_ints, num ].min.downto(1).flat_map do |idx|
      integer_partition(num - idx, idx).map { |rest| [ idx, *rest ] }
    end
  end

  # Converts the integer partitions of a number to hash format
  def hash_integer_partition(count, randomize_exercises)
    @hash_integer_partitions ||= {}
    @hash_integer_partitions[count] ||= begin
      partitions = integer_partition(count)
      partitions.shuffle if randomize_exercises
      partitions.map do |partition|
        Hash.new(0).tap do |group|
          partition.each { |num| group[num] += 1 }
        end
      end
    end
  end

  # Picks an integer partition for a number that can be completely filled by the available exercises
  def choose_exact_integer_partition(count, exercises_by_num_questions, randomize_exercises)
    hash_integer_partition(count, randomize_exercises).each do |partition|
      return partition if partition.all? do |num, count|
        !exercises_by_num_questions[num].nil? && exercises_by_num_questions[num].size >= count
      end
    end

    nil
  end

  # Chooses exercises for the given integer partition
  def choose_integer_partition_exercises(partition, exercises_by_num_questions)
    (partition || []).flat_map do |num_questions, times|
      exercises_by_num_questions[num_questions].first(times)
    end
  end

  # 1. Finds an integer partition for the lowest number greater than or equal to count
  #    that can be completely filled by new exercises
  # 2. If (1) not found, repeats (1) with all exercises
  # 3. If (2) not found, repeats (2) but trying to find the highest number lower than count
  def choose_exercises(new_exercises, exercises, count, randomize_exercises)
    return [] if exercises.empty? || count == 0

    exercises_by_num_questions = exercises.group_by(&:number_of_questions)
    chosen_integer_partition = nil

    # First look only at the new exercises
    unless new_exercises.empty?
      new_count = [ count, new_exercises.map(&:number_of_questions).sum ].min
      new_exercises_by_num_questions = new_exercises.group_by(&:number_of_questions)

      new_count.upto(new_count + MAX_DROPPED_QUESTION_PARTS).each do |num_questions|
        chosen_integer_partition = choose_exact_integer_partition(
          num_questions, new_exercises_by_num_questions, randomize_exercises
        )

        break unless chosen_integer_partition.nil?
      end

      unless chosen_integer_partition.nil?
        repeated_count = count - new_count
        return choose_integer_partition_exercises(
          chosen_integer_partition, new_exercises_by_num_questions
        ) if repeated_count == 0

        repeated_exercises = exercises - new_exercises
        repeated_exercises_by_num_questions = repeated_exercises.group_by(&:number_of_questions)

        repeated_integer_partition = nil
        repeated_count.upto(repeated_count + MAX_DROPPED_QUESTION_PARTS).each do |num_questions|
          repeated_integer_partition = choose_exact_integer_partition(
            num_questions, repeated_exercises_by_num_questions, randomize_exercises
          )

          break unless repeated_integer_partition.nil?
        end

        return choose_integer_partition_exercises(
          chosen_integer_partition, new_exercises_by_num_questions
        ) + choose_integer_partition_exercises(
          repeated_integer_partition, repeated_exercises_by_num_questions
        ) unless repeated_integer_partition.nil?
      end
    end

    # We couldn't find enough new exercises, so look at all exercises together
    count.upto(count + MAX_DROPPED_QUESTION_PARTS).each do |num_questions|
      chosen_integer_partition = choose_exact_integer_partition(
        num_questions, exercises_by_num_questions, randomize_exercises
      )

      break unless chosen_integer_partition.nil?
    end

    return choose_integer_partition_exercises(
      chosen_integer_partition, exercises_by_num_questions
    ) unless chosen_integer_partition.nil?

    # We still couldn't find enough exercises, so look at numbers smaller than count
    count.downto(1).each do |num_questions|
      chosen_integer_partition = choose_exact_integer_partition(
        num_questions, exercises_by_num_questions, randomize_exercises
      )

      break unless chosen_integer_partition.nil?
    end

    choose_integer_partition_exercises chosen_integer_partition, exercises_by_num_questions
  end
end
