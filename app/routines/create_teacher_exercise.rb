class CreateTeacherExercise
  lev_routine transaction: :read_committed, express_output: :exercise

  uses_routine Content::Routines::TagResource, as: :tag
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  def exec(course:, page:, content:, profile:, derived_from_id: nil, images: nil, tags: [], copyable: nil, anonymize: nil, save: false)
    tags << ['type:practice']

    wrapper = OpenStax::Exercises::V1::Exercise.new(content: content.to_json)
    derived_from = derived_from_id && find_derivable_exercise(course, derived_from_id)

    exercise = Content::Models::Exercise.new(
      content: wrapper.content,
      page: page,
      user_profile_id: profile.id,
      nickname: wrapper.nickname,
      title: wrapper.title,
      preview: wrapper.preview,
      context: wrapper.context,
      number_of_questions: wrapper.questions.size,
      question_answer_ids: wrapper.question_answer_ids,
      has_interactive: wrapper.has_interactive?,
      has_video: wrapper.has_video?,
      derived_from: derived_from,
      anonymize_author: anonymize || false,
      is_copyable: copyable || true
    )
    exercise.images.attach(images) if images
    exercise.save if save

    run(
      :tag,
      ecosystem: course.ecosystem,
      resource: exercise,
      tags: tags,
      tagging_class: Content::Models::ExerciseTag,
      save_tags: save
    )

    run(
      :populate_exercise_pools,
      book: exercise.page.book,
      pages: [page],
      save: save
    )

    outputs.exercise = exercise
  end

  def find_derivable_exercise(course, exercise_id)
    outs = FilterExcludedExercises.call(
      exercises: Content::Models::Exercise.where(id: exercise_id),
      profile_ids: course.related_teacher_profile_ids
    ).outputs

    if outs.exercises.select(&:is_copyable).empty?
      fatal_error(
        code:    :derived_from_not_accessible,
        message: 'User does not have access to derive the requested exercise'
      )
    end

    outs.exercises.first
  end
end
