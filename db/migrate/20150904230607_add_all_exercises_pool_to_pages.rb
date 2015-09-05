class AddAllExercisesPoolToPages < ActiveRecord::Migration
  def change
    add_reference :content_pages, :content_all_exercises_pool
    add_foreign_key :content_pages, :content_pools, column: :content_all_exercises_pool_id,
                                                    on_update: :cascade, on_delete: :nullify
  end
end
