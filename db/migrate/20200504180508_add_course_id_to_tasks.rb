class AddCourseIdToTasks < ActiveRecord::Migration[5.2]
  def up
    add_reference :tasks_tasks, :course_profile_course,
                  foreign_key: { on_update: :cascade, on_delete: :cascade }

    BackgroundMigrate.perform_later 'up', 20200521193851
  end

  def down
    BackgroundMigrate.perform_later 'down', 20200521193851

    remove_reference :tasks_tasks, :course_profile_course,
                     foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
