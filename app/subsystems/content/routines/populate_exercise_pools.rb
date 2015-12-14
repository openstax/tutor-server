class Content::Routines::PopulateExercisePools

  lev_routine outputs: { pools: :_self,
                         book: :_self,
                         chapters: :_self,
                         pages: :_self }

  protected

  def exec(book:, save: true)
    ecosystem = book.ecosystem
    # Use preload here instead of eager_load here to avoid a memory usage spike
    chapters = book.chapters.preload(pages: { exercises: { exercise_tags: :tag } })

    set(pools: chapters.flat_map do |chapter|
      ecosystem = chapter.ecosystem
      pages = chapter.pages

      # Populate page pools
      page_pools = pages.flat_map do |page|
        page.reading_dynamic_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                              pool_type: :reading_dynamic)
        page.reading_try_another_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                                  pool_type: :reading_try_another)
        page.homework_core_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                            pool_type: :homework_core)
        page.homework_dynamic_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                               pool_type: :homework_dynamic)
        page.practice_widget_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                              pool_type: :practice_widget)
        page.all_exercises_pool = Content::Models::Pool.new(ecosystem: ecosystem,
                                                            pool_type: :all_exercises)

        page.exercises.each do |exercise|
          tags = Set.new exercise.exercise_tags.collect{ |et| et.tag.value }

          # iReading Dynamic (Concept Coach)
          page.reading_dynamic_pool.content_exercise_ids << exercise.id \
            if (
              tags.include?('k12phys') && tags.include?('os-practice-concepts')
            ) || (
              tags.include?('apbio') && tags.include?('ost-chapter-review') && \
              tags.include?('review') && tags.include?('time-short')
            )

          # iReading Try Another/Refresh my Memory
          page.reading_try_another_pool.content_exercise_ids << exercise.id \
            if tags.include?('os-practice-problems')

          # Homework Core (Assignment Builder)
          page.homework_core_pool.content_exercise_ids << exercise.id \
            if tags.include?('ost-chapter-review')

          # Homework Dynamic
          page.homework_dynamic_pool.content_exercise_ids << exercise.id \
            if (
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
                tags.include?('critical-thinking') || tags.include?('ap-test-prep') || (
                  tags.include?('review') && (
                    tags.include?('time-medium') || tags.include?('time-long')
                  )
                )
              )
            )

          # Practice Widget
          page.practice_widget_pool.content_exercise_ids << exercise.id

          # All Exercises
          page.all_exercises_pool.content_exercise_ids << exercise.id
        end

        [page.reading_dynamic_pool, page.reading_try_another_pool, page.homework_core_pool,
         page.homework_dynamic_pool, page.practice_widget_pool, page.all_exercises_pool]
      end

      # Populate chapter pools
      all_exercise_ids = pages.flat_map{ |page| page.all_exercises_pool.content_exercise_ids }.uniq
      chapter.all_exercises_pool = Content::Models::Pool.new(
        ecosystem: ecosystem, pool_type: :all_exercises, content_exercise_ids: all_exercise_ids
      )

      [chapter.all_exercises_pool] + page_pools
    end)

    set(book: book)
    set(chapters: chapters)
    set(pages: chapters.flat_map(&:pages))

    return unless save

    pools = result.pools.flatten
    pools.each{ |pool| pool.uuid = SecureRandom.uuid }
    Content::Models::Pool.import! pools

    # Save ids in page/chapter tables and clear associations so pools get reloaded next time
    result.pages.each do |page|
      page.save!
      page.clear_association_cache
    end
    chapters.each do |chapter|
      chapter.save!
      chapter.clear_association_cache
    end
  end
end
