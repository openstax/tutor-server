class Content::Routines::PopulateExercisePools

  lev_routine

  protected

  def exec(pages:)
    outputs[:pools] = pages.collect do |page|
      reading_dynamic_pool = Content::Models::Pool.new(page: page,
                                                       pool_type: :reading_dynamic)
      reading_try_another_pool = Content::Models::Pool.new(page: page,
                                                           pool_type: :reading_try_another)
      homework_core_pool = Content::Models::Pool.new(page: page,
                                                     pool_type: :homework_core)
      homework_dynamic_pool = Content::Models::Pool.new(page: page,
                                                        pool_type: :homework_dynamic)
      practice_widget_pool = Content::Models::Pool.new(page: page,
                                                       pool_type: :practice_widget)

      page.exercises.each do |exercise|
        tags = Set.new exercise.exercise_tags.collect{ |et| et.tag.value }

        # iReading Dynamic (Concept Coach)
        reading_dynamic_pool.content_exercise_ids << exercise.id \
          if (
            tags.include?('k12phys') && tags.include?('os-practice-concepts')
          ) || (
            tags.include?('apbio') && tags.include?('ost-chapter-review') && \
            tags.include?('review') && tags.include?('time-short')
          )

        # iReading Try Another/Refresh my Memory
        reading_try_another_pool.content_exercise_ids << exercise.id \
          if tags.include?('os-practice-problems')

        # Homework Core (Assignment Builder)
        homework_core_pool.content_exercise_ids << exercise.id \
          if tags.include?('ost-chapter-review')

        # Homework Dynamic
        homework_dynamic_pool.content_exercise_ids << exercise.id \
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
        practice_widget_pool.content_exercise_ids << exercise.id
      end

      [reading_dynamic_pool, reading_try_another_pool,
       homework_core_pool, homework_dynamic_pool, practice_widget_pool]
    end
  end
end
