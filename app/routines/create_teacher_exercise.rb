class CreateTeacherExercise
  lev_routine transaction: :read_committed

  uses_routine Content::Routines::TagResource, as: :tag
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  ALLOWED_TAGS  = %w(a img b i iframe)
  ALLOWED_ATTRS = %w(alt src title width height)

  protected

  def exec(course:, page:, content:, profile:, derived_from_id: nil, images: [], tags: [], anonymize: false, save: false)
    wrapper = OpenStax::Exercises::V1::Exercise.new(content: sanitize(content))
    tags << ['type:practice']

    derived_from = derived_from_id && find_derivable_exercise(course, derived_from_id)
    version = (derived_from&.version || 0) + 1

    exercise = Content::Models::Exercise.new(
      content: wrapper.content,
      images: images,
      page: page,
      number: derived_from&.number,
      version: version,
      user_profile_id: profile.id,
      nickname: wrapper.nickname,
      title: wrapper.title,
      preview: wrapper.preview,
      context: wrapper.context,
      content: wrapper.content,
      number_of_questions: wrapper.questions.size,
      question_answer_ids: wrapper.question_answer_ids,
      has_interactive: wrapper.has_interactive?,
      has_video: wrapper.has_video?,
      derived_from: derived_from,
      anonymize_author: anonymize
    )

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

    if outs.exercises.empty?
      fatal_error(
        code:    :derived_from_not_accessible,
        message: 'User does not have access to derive the requested exercise'
      )
    end

    outs.exercises.first
  end

  def sanitize(html)
    sanitizer = Rails::Html::SafeListSanitizer.new
    sanitizer.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
  end
end
