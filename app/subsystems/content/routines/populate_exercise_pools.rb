class Content::Routines::PopulateExercisePools
  # TODO: Add per-book pool logic to the book map
  HS_UUIDS = [
    '334f8b61-30eb-4475-8e05-5260a4866b4b',
    'd52e93f4-8653-4273-86da-3850001c0786',
    '93e2b09d-261c-4007-a987-0b3062fe154b'
  ]

  lev_routine

  protected

  def exec(book:, pages: nil, save: true)
    ecosystem = book.ecosystem
    # Use preload here instead of eager_load here to avoid a memory usage spike
    pages ||= book.pages.preload(exercises: :tags)

    hs_logic = HS_UUIDS.include?(book.uuid)
    college_logic = !hs_logic

    pages.each do |page|
      page.exercises.each do |exercise|
        # All Exercises
        page.all_exercise_ids << exercise.id

        tags = exercise.tags.map(&:value)

        # Homework Core (Assignment Builder)
        page.homework_core_exercise_ids << exercise.id \
          if (hs_logic && tags.include?('ost-chapter-review')) ||
             (college_logic && tags.include?('type:practice'))

        # Multiparts can only be in the All Exercises and Homework Core pools
        next if exercise.is_multipart?

        # Reading Dynamic (Concept Coach)
        page.reading_dynamic_exercise_ids << exercise.id \
          if (
            hs_logic && (
              (
                tags.include?('k12phys') && tags.include?('os-practice-concepts')
              ) || (
                tags.include?('apbio') &&
                tags.include?('ost-chapter-review') &&
                tags.include?('review') && (
                  tags.include?('time:short') || tags.include?('time-short')
                )
              )
            )
          ) || (
            college_logic && (
              tags.include?('type:conceptual') ||
              tags.include?('type:recall') ||
              tags.include?('type:conceptual-or-recall')
            )
          )

        # Reading Context-Dependent
        page.reading_context_exercise_ids << exercise.id \
          if (hs_logic && tags.include?('os-practice-problems')) || college_logic

        # Homework Dynamic
        page.homework_dynamic_exercise_ids << exercise.id \
          if (
            hs_logic && (
              (
                tags.include?('k12phys') && (
                  tags.include?('os-practice-problems') || (
                    tags.include?('ost-chapter-review') && (
                      tags.include?('concept') || \
                      tags.include?('problem') || \
                      tags.include?('critical-thinking')
                    )
                  )
                )
              ) || (
                tags.include?('apbio') && tags.include?('ost-chapter-review') && (
                  tags.include?('critical-thinking') ||
                  tags.include?('ap-test-prep') || (
                    tags.include?('review') && (
                      tags.include?('time:medium') || tags.include?('time:long') ||
                      tags.include?('time-medium') || tags.include?('time-long')
                    )
                  )
                )
              )
            )
          ) || (
            college_logic && tags.include?('type:practice')
          )

        # Practice Widget
        page.practice_widget_exercise_ids << exercise.id \
          unless exercise.requires_context?
      end
    end

    outputs.book = book
    outputs.pages = pages

    return unless save

    outputs.pages.each(&:save!)
  end
end
