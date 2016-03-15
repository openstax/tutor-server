class ChooseExercises

  lev_routine express_output: :exercises

  def exec(exercises:, count:, history:, allow_repeats: true,
           randomize_exercises: true, randomize_order: true)
    all_worked_exercise_numbers = history.exercises.flatten.map(&:number).uniq

    exercises = exercises.uniq
    exercises = exercises.shuffle if randomize_exercises

    new_exercises = []
    repeated_exercises = []

    # Partition exercises into new exercises and the repeated exercises
    exercises.each do |ex|
      if all_worked_exercise_numbers.include?(ex.number)
        repeated_exercises << ex
      else
        new_exercises << ex
      end
    end

    new_exercises_count = [candidate_exercises.size, count].min
    repeated_exercises_count = allow_repeats ? \
                                [repeated_exercises.size, count - new_exercises_count].min : 0

    chosen_exercises = new_exercises.first(new_exercises_count) + \
                       repeated_exercises.first(repeated_exercises_count)

    chosen_exercises = chosen_exercises.shuffle if randomize_order

    outputs[:exercises] = chosen_exercises
  end

end
