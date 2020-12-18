class Content::Routines::RemapPracticeQuestionExercises
  lev_routine

  protected

  def exec(ecosystem:, save: false)
    mapped_ids = {}
    new_ids_by_number = {}
    old_ids_by_number = {}

    new_ids_by_number = ecosystem.exercises.pluck(:number, :id).to_h
    old_ids_by_number = Tasks::Models::PracticeQuestion
                          .joins(:exercise)
                          .where(exercise: { number: new_ids_by_number.keys })
                          .distinct.pluck(:number, :content_exercise_id)
                          .to_h

    old_ids_by_number.each do |number, old_id|
      new_id = new_ids_by_number[number]
      mapped_ids[old_id] = new_id if old_id != new_id
    end

    outputs.mapped_ids = mapped_ids

    return unless save

    mapped_ids.each do |old_id, new_id|
      Tasks::Models::PracticeQuestion
        .where(content_exercise_id: old_id)
        .update_all(content_exercise_id: new_id)
    end
  end
end
