class AddAllExercisesPoolToChapters < ActiveRecord::Migration[4.2]
  def change
    add_reference :content_chapters, :content_all_exercises_pool
    add_foreign_key :content_chapters, :content_pools, column: :content_all_exercises_pool_id,
                                                       on_update: :cascade, on_delete: :nullify
  end
end
