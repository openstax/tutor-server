class Content::Routines::PopulateExercisePools

  # TODO: Add per-book pool logic to the book map
  HS_UUIDS = ['334f8b61-30eb-4475-8e05-5260a4866b4b',
              'd52e93f4-8653-4273-86da-3850001c0786',
              '93e2b09d-261c-4007-a987-0b3062fe154b']

  lev_routine express_output: :pools

  protected

  def exec(book:, save: true)
    ecosystem = book.ecosystem
    # Use preload here instead of eager_load here to avoid a memory usage spike
    chapters = book.chapters.preload(pages: { exercises: :tags })

    hs_logic = HS_UUIDS.include?(book.uuid)
    college_logic = !hs_logic

    outputs[:pools] = chapters.flat_map do |chapter|
      ecosystem = chapter.ecosystem
      pages = chapter.pages

      # Populate page pools
      page_pools = pages.flat_map do |page|
        page.reading_dynamic_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                              pool_type: :reading_dynamic)
        page.reading_context_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                              pool_type: :reading_context)
        page.homework_core_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                            pool_type: :homework_core)
        page.homework_dynamic_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                               pool_type: :homework_dynamic)
        page.practice_widget_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                              pool_type: :practice_widget)
        page.concept_coach_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                            pool_type: :concept_coach)
        page.all_exercises_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                            pool_type: :all_exercises)

        page.exercises.each do |exercise|
          tags = exercise.tags.map(&:value)

          # All Exercises
          page.all_exercises_pool.content_exercise_ids << exercise.id

          # Homework Core (Assignment Builder)
          page.homework_core_pool.content_exercise_ids << exercise.id \
            if (hs_logic && tags.include?('ost-chapter-review')) ||
               (college_logic && tags.include?('type:practice'))

          # Multiparts can only be in the All Exercises and Homework Core pools
          next if exercise.is_multipart?

          # Reading Dynamic (Concept Coach)
          page.reading_dynamic_pool.content_exercise_ids << exercise.id \
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
          page.reading_context_pool.content_exercise_ids << exercise.id \
            if (hs_logic && tags.include?('os-practice-problems')) || college_logic

          # Homework Dynamic
          page.homework_dynamic_pool.content_exercise_ids << exercise.id \
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

          # Concept Coach
          page.concept_coach_pool.content_exercise_ids << exercise.id \
            if tags.include?('ost-type:concept-coach')

          # Practice Widget
          page.practice_widget_pool.content_exercise_ids << exercise.id \
            unless exercise.requires_context?
        end

        [page.reading_dynamic_pool, page.reading_context_pool, page.homework_core_pool,
         page.homework_dynamic_pool, page.practice_widget_pool, page.concept_coach_pool,
         page.all_exercises_pool]
      end

      # Populate chapter pools
      all_exercise_ids = pages.flat_map{ |page| page.all_exercises_pool.content_exercise_ids }.uniq
      chapter.all_exercises_pool = Content::Models::Pool.new(
        ecosystem: ecosystem, pool_type: :all_exercises, content_exercise_ids: all_exercise_ids
      )

      [chapter.all_exercises_pool] + page_pools
    end

    outputs[:book] = book
    outputs[:chapters] = chapters
    outputs[:pages] = chapters.flat_map(&:pages)

    return unless save

    pools = outputs[:pools].flatten
    pools.each{ |pool| pool.uuid = SecureRandom.uuid }
    Content::Models::Pool.import pools, validate: false

    # Save ids in page/chapter tables and clear associations so pools get reloaded next time
    outputs[:pages].each do |page|
      page.save!
      page.clear_association_cache
    end
    chapters.each do |chapter|
      chapter.save!
      chapter.clear_association_cache
    end
  end
end
