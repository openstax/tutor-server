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

    # Invalidate preview courses that accidentally got teacher-created exercises
    CourseProfile::Models::Course.where(
      is_preview: true, preview_claimed_at: nil
    ).where(
      <<~WHERE
        EXISTS (
          SELECT * FROM "tasks_tasks"
          INNER JOIN "tasks_task_steps"
            ON "tasks_task_steps"."tasks_task_id" = "tasks_tasks"."id"
          INNER JOIN "tasks_tasked_exercises"
            ON "tasks_task_steps"."tasked_type" = 'Tasks::Models::TaskedExercise' AND
               "tasks_task_steps"."tasked_id" = "tasks_tasked_exercises"."id"
          INNER JOIN "content_exercises"
            ON "tasks_tasked_exercises"."content_exercise_id" = "content_exercises"."id"
          WHERE "content_exercises"."user_profile_id" != 0
        )
      WHERE
    ).update_all(preview_claimed_at: Time.now)
  end

  def down
    # We'll write this if we need to
  end
end
