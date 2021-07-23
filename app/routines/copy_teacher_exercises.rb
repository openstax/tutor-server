class CopyTeacherExercises
  lev_routine

  uses_routine Content::Routines::TagResource, as: :tag
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  def exec(mapping:, save: true)
    destination_pages = mapping.map do |source_uuid, destination_uuid|
      Content::Models::Page.where(uuid: destination_uuid).order(:created_at).last.tap do |dest_page|
        source_page_ids = Content::Models::Page.where(uuid: source_uuid).pluck(:id)
        exercises = Content::Models::Exercise.where(content_page_id: source_page_ids).where.not(
          user_profile_id: 0
        ).find_each.map do |source_exercise|
          Content::Models::Exercise.new(
            page: dest_page,
            user_profile_id: source_exercise.user_profile_id,
            content: source_exercise.content,
            nickname: source_exercise.nickname,
            title: source_exercise.title,
            preview: source_exercise.preview,
            context: source_exercise.context,
            number_of_questions: source_exercise.number_of_questions,
            question_answer_ids: source_exercise.question_answer_ids,
            has_interactive: source_exercise.has_interactive,
            has_video: source_exercise.has_video,
            derived_from: source_exercise.derived_from,
            anonymize_author: source_exercise.anonymize_author,
            is_copyable: source_exercise.is_copyable
          ).tap do |new_exercise|
            new_exercise.images.attach(source_exercise.images) if source_exercise.images.present?

            run(
              :tag,
              ecosystem: dest_page.book.ecosystem,
              resource: new_exercise,
              tags: source_exercise.tags,
              tagging_class: Content::Models::ExerciseTag
            )

            new_exercise.set_teacher_exercise_identities
            # Set derived_from after calling set_teacher_exercise_identities
            # so the new exercise is not a new version
            new_exercise.derived_from = source_exercise
          end
        end

        Content::Models::Exercise.import(exercises, recursive: true, validate: false) if save
      end
    end

    destination_pages.group_by(&:book).each do |book, destination_pages|
      run :populate_exercise_pools, book: book, pages: destination_pages, save: save
    end
  end
end
