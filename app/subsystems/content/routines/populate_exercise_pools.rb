class Content::Routines::PopulateExercisePools
  DYNAMIC_MPQ_UUIDS = [
    '0a621f27-abe1-4c17-8f1c-d80d07958977',
    '36004586-651c-4ded-af87-203aca22d946'
  ]

  lev_routine

  protected

  def exec(book:, pages: nil, save: true)
    pages ||= book.pages.to_a
    ActiveRecord::Associations::Preloader.new.preload(pages, exercises: :tags)

    dynamic_multipart = DYNAMIC_MPQ_UUIDS.include?(book.uuid)

    pages.each do |page|
      page.exercises.each do |exercise|
        # All Exercises
        page.all_exercise_ids << exercise.id

        tags = exercise.tags.map(&:value)

        # Homework Core (Assignment Builder)
        page.homework_core_exercise_ids << exercise.id \
          if tags.include?('assignment-type:homework')

        # Multiparts (except for APUSH) and tree response only exercises are
        # limited to the All Exercises and Homework Core pools
        next if (!dynamic_multipart && exercise.is_multipart?) || exercise.is_free_response_only?

        # Reading Dynamic (Concept Coach)
        page.reading_dynamic_exercise_ids << exercise.id \
          if tags.include?('assignment-type:reading')

        # Reading Context-Dependent
        page.reading_context_exercise_ids << exercise.id

        # Homework Dynamic
        page.homework_dynamic_exercise_ids << exercise.id \
          if tags.include?('assignment-type:homework')

        # Practice Widget
        page.practice_widget_exercise_ids << exercise.id \
          unless exercise.requires_context?
      end
    end

    outputs.book = book
    outputs.pages = pages

    return unless save

    pages.each(&:save!)
  end
end
