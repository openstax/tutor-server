class Content::Routines::RemapTeacherExercises
  lev_routine

  uses_routine Content::Routines::TagResource, as: :tag

  protected

  def exec(ecosystem:, save: false)
    updated_exercise_ids_by_page_id = {}

    ecosystem_ids, page_ids = Content::Models::Exercise
                                .created_by_teacher
                                .joins(:book)
                                .distinct
                                .pluck(:content_ecosystem_id, :content_page_id)
                                .transpose

    return unless ecosystem_ids && page_ids

    ecosystems = Content::Models::Ecosystem.where(id: ecosystem_ids.uniq)

    map = Content::Map.find_or_create_by(
      from_ecosystems: ecosystems, to_ecosystem: ecosystem
    )
    mapped = map.map_page_ids(page_ids: page_ids).compact.reject do |k, v|
      k.to_s == v.to_s
    end

    mapped.each do |from, to|
      exercises = Content::Models::Exercise.created_by_teacher.where(content_page_id: from)

      updated_exercise_ids_by_page_id[from.to_s] = []

      next unless save

      exercises.find_each do |exercise|
        dup_exercise = exercise.dup
        dup_exercise.content_page_id = to
        dup_exercise.save(validate: false)
        tag_values = exercise.tags.pluck(:value)

        run(
          :tag,
          ecosystem: ecosystem,
          resource: dup_exercise,
          tags: tag_values,
          tagging_class: Content::Models::ExerciseTag,
          save_tags: true
        )

        updated_exercise_ids_by_page_id[from.to_s] << [exercise.id, dup_exercise.id]
      end
    end

    outputs.updated_exercise_ids_by_page_id = updated_exercise_ids_by_page_id
    outputs.mapped_page_ids = mapped
  end
end
