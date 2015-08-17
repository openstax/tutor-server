class Content::Routines::PopulateExercisePools

  lev_routine express_output: :pools

  protected

  def exec(pages:, save: true)
    pages = [pages].flatten
    outputs[:pools] = pages.collect do |page|
      ecosystem = page.ecosystem

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
      end

      [page.reading_dynamic_pool, page.reading_try_another_pool,
       page.homework_core_pool, page.homework_dynamic_pool, page.practice_widget_pool]
    end

    outputs[:pages] = pages

    return unless save

    pools = outputs[:pools].flatten
    pools.each{ |pool| pool.uuid = SecureRandom.uuid }
    Content::Models::Pool.import! pools
    pages.each{ |page| page.save! }
  end
end
