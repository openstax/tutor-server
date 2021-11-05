class GetPracticeQuestionExercises
  lev_routine transaction: :no_transaction, express_output: :exercises

  def exec(role:, course:)
    exercise_and_ecosystem_ids = role.practice_questions
                                   .joins(exercise: :ecosystem)
                                   .pluck("content_ecosystems.id", :content_exercise_id)

    exercises = []
    exercise_ids_grouped_by_ecosystem_id = Hash.new {|h,k| h[k] = [] }

    exercise_and_ecosystem_ids.map do |id_group|
      exercise_ids_grouped_by_ecosystem_id[id_group[0]] << id_group[1]
    end

    exercise_ids_grouped_by_ecosystem_id.each do |ecosystem_id, exercise_ids|
      ecosystem = Content::Models::Ecosystem.find(ecosystem_id)

      exercises << GetExercises.call(
        course: course,
        ecosystem: ecosystem,
        exercise_ids: exercise_ids
      ).outputs.exercises
    end

    outputs.exercises = exercises.flatten
  end
end
