class ChooseExercises

  lev_routine express_output: :exercises

  def exec(exercises:, count:, history:, allow_repeats: true,
           randomize_exercises: true, randomize_order: true,
           allow_multipart: true
          )
    worked_exercise_numbers_set = Set.new history.exercise_numbers.flatten

    exercises = exercises.uniq
    unless allow_multipart
      exercises.reject!{ |exercise| exercise.to_model.is_multipart? }
    end

    exercises = exercises.shuffle if randomize_exercises

    # Partition exercises into new exercises and the repeated exercises
    repeated_exercises, new_exercises = exercises.partition do |ex|
      worked_exercise_numbers_set.include?(ex.number)
    end

    new_exercises_count = [new_exercises.size, count].min
    repeated_exercises_count = allow_repeats ? \
                                 [repeated_exercises.size, count - new_exercises_count].min : 0

    chosen_exercises = new_exercises.first(new_exercises_count) + \
                       repeated_exercises.first(repeated_exercises_count)

    chosen_exercises = chosen_exercises.shuffle if randomize_order

    outputs[:exercises] = chosen_exercises
  end

end
