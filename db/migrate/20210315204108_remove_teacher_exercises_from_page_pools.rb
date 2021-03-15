class RemoveTeacherExercisesFromPagePools < ActiveRecord::Migration[5.2]
  def up
    teacher_exercise_ids = Content::Models::Exercise.created_by_teacher.pluck(:id)
    page_ids = Content::Models::Exercise.created_by_teacher.distinct.pluck(:content_page_id)

    Content::Models::Page.select(
      :id, :content_book_id,
      :all_exercise_ids, :homework_core_exercise_ids, :reading_dynamic_exercise_ids,
      :reading_context_exercise_ids, :homework_dynamic_exercise_ids, :practice_widget_exercise_ids
    ).where(id: page_ids).preload(:book, exercises: :tags).group_by(&:book).each do |book, pages|
      page.all_exercise_ids -= teacher_exercise_ids
      page.homework_core_exercise_ids -= teacher_exercise_ids
      page.reading_dynamic_exercise_ids -= teacher_exercise_ids
      page.reading_context_exercise_ids -= teacher_exercise_ids
      page.homework_dynamic_exercise_ids -= teacher_exercise_ids
      page.practice_widget_exercise_ids -= teacher_exercise_ids
      page.save!
    end
  end

  def down
    # We'll write this if we need to
  end
end
