class AddClonedFromIdToCoursesAndTaskPlans < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :cloned_from_id, :integer
    add_column :tasks_task_plans, :cloned_from_id, :integer

    add_index :course_profile_courses, :cloned_from_id
    add_index :tasks_task_plans, :cloned_from_id

    add_foreign_key :course_profile_courses, :course_profile_courses,
                    column: :cloned_from_id, on_update: :cascade, on_delete: :nullify
    add_foreign_key :tasks_task_plans, :tasks_task_plans,
                    column: :cloned_from_id, on_update: :cascade, on_delete: :nullify
  end
end
