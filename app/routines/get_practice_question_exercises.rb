class GetPracticeQuestionExercises
  lev_routine transaction: :no_transaction, express_output: :exercises

  def exec(role:, course:)
    uuids = role.practice_questions
                .joins(tasked_exercise: :exercise)
                .pluck("content_exercises.uuid").uniq

    exercise_and_ecosystem_ids =
      Content::Models::Exercise.select('DISTINCT ON ("content_exercises"."number") "content_exercises".*')
        .joins(book: :ecosystem)
        .where(book: { content_ecosystem_id: course.ecosystems.map(&:id) }, uuid: uuids)
        .order(:number, version: :desc)
        .pluck("content_ecosystems.id", "content_exercises.id")

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
