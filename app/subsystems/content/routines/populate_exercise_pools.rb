class Content::Routines::PopulateExercisePools

  lev_routine

  protected

  def exec(pages:)
    pages.each do |page|
      page.exercises.each do |exercise|
        tags = Set.new exercise.exercise_tags.collect{ |et| et.tag.value }

        # iReading Dynamic (Concept Coach)
        page.reading_dynamic_exercise_ids << exercise.id \
          if (
            tags.include?('k12phys') && tags.include?('os-practice-concepts')
          ) || (
            tags.include?('apbio') && tags.include?('ost-chapter-review') && \
            tags.include?('review') && tags.include?('time-short')
          )

        # iReading Try Another/Refresh my Memory
        page.reading_try_another_exercise_ids << exercise.id \
          if tags.include?('os-practice-problems')

        # Homework Core (Assignment Builder)
        page.homework_core_exercise_ids << exercise.id if tags.include?('ost-chapter-review')

        # Homework Dynamic
        page.homework_dynamic_exercise_ids << exercise.id \
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
        page.practice_widget_exercise_ids << exercise.id
      end
    end

    outputs[:pages] = pages
  end
end
