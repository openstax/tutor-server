class CreateTeacherExercise
  lev_routine

  uses_routine Content::Routines::TagResource, as: :tag

  ALLOWED_TAGS  = %w(a img b i iframe)
  ALLOWED_ATTRS = %w(alt src title width height)

  protected

  def exec(ecosystem:, page:, content:, profile:, images: [], tags: [], anonymize: false, save: false)
    wrapper = OpenStax::Exercises::V1::Exercise.new(content: sanitize(content))
    tags << ['type:practice']

    exercise = Content::Models::Exercise.new(
      content: wrapper.content,
      images: images,
      page: page,
      version: 1,
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
      anonymize_author: anonymize
    )

    exercise.save if save

    run(
      :tag,
      ecosystem: ecosystem,
      resource: exercise,
      tags: tags,
      tagging_class: Content::Models::ExerciseTag,
      save_tags: save
    )

    Content::Routines::PopulateExercisePools[
      book: exercise.page.book,
      pages: [page],
      save: save
    ]

    outputs.exercise = exercise
  end

  def sanitize(html)
    sanitizer = Rails::Html::SafeListSanitizer.new
    sanitizer.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
  end
end
