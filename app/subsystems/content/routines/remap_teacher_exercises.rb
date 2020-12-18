class Content::Routines::RemapTeacherExercises
  lev_routine

  uses_routine Content::Routines::TagResource, as: :tag

  protected

  def exec(ecosystem:, save: false)
    updated_exercise_ids_by_page_id = {}

    ecosystem_ids, page_ids = Content::Models::Exercise
                                .created_by_teacher
                                .joins(:book)
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
      updated_exercise_ids_by_page_id[from.to_s] = exercises.map(&:id).sort
      exercises.update_all(content_page_id: to) if save

      next unless save

      exercises.each do |exercise|
        run(
          :tag,
          ecosystem: ecosystem,
          resource: exercise,
          tags: exercise.tags.pluck(:value),
          tagging_class: Content::Models::ExerciseTag,
          save_tags: true
        )
      end
    end

    outputs.updated_exercise_ids_by_page_id = updated_exercise_ids_by_page_id
    outputs.mapped_page_ids = mapped
  end
end
