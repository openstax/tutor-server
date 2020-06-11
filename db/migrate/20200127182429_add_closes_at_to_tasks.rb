class AddClosesAtToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasking_plans, :closes_at_ntz, :datetime
    add_column :tasks_tasks, :closes_at_ntz, :datetime
    add_column :tasks_task_caches, :closes_at, :datetime
    add_column :tasks_period_caches, :closes_at, :datetime

    reversible do |dir|
      dir.up do
        # All TaskPlans have a Course as the owner, so this query should update all of them
        # The INTERVAL '1 day' should prevent errors due to the timezone
        Tasks::Models::TaskingPlan.update_all(
          <<~UPDATE_SQL
            "closes_at_ntz" = "course_profile_courses"."ends_at" - INTERVAL '1 day'
            FROM "tasks_task_plans"
              INNER JOIN "course_profile_courses"
                ON "course_profile_courses"."id" = "tasks_task_plans"."owner_id"
            WHERE "tasks_task_plans"."id" = "tasks_tasking_plans"."tasks_task_plan_id"
              AND "tasks_task_plans"."owner_type" = 'CourseProfile::Models::Course'
          UPDATE_SQL
        )

        Tasks::Models::Task.update_all(
          <<~UPDATE_SQL
            "closes_at_ntz" = "tasks_tasking_plans"."closes_at_ntz"
            FROM "tasks_taskings"
            INNER JOIN "course_membership_students"
              ON "course_membership_students"."entity_role_id" = "tasks_taskings"."entity_role_id"
            INNER JOIN "tasks_tasking_plans"
              ON "tasks_tasking_plans"."target_type" = 'CourseMembership::Models::Period'
              AND "tasks_tasking_plans"."target_id" =
                "course_membership_students"."course_membership_period_id"
            WHERE "tasks_tasks"."tasks_task_plan_id" IS NOT NULL
              AND "tasks_tasking_plans"."tasks_task_plan_id" = "tasks_tasks"."tasks_task_plan_id"
              AND "tasks_taskings"."tasks_task_id" = "tasks_tasks"."id"
          UPDATE_SQL
        )

        Tasks::Models::Task.update_all(
          <<~UPDATE_SQL
            "closes_at_ntz" = "tasks_tasking_plans"."closes_at_ntz"
            FROM "tasks_taskings"
            INNER JOIN "course_membership_teacher_students"
              ON "course_membership_teacher_students"."entity_role_id" =
                "tasks_taskings"."entity_role_id"
            INNER JOIN "tasks_tasking_plans"
              ON "tasks_tasking_plans"."target_type" = 'CourseMembership::Models::Period'
              AND "tasks_tasking_plans"."target_id" =
                "course_membership_teacher_students"."course_membership_period_id"
            WHERE "tasks_tasks"."tasks_task_plan_id" IS NOT NULL
              AND "tasks_tasking_plans"."tasks_task_plan_id" = "tasks_tasks"."tasks_task_plan_id"
              AND "tasks_taskings"."tasks_task_id" = "tasks_tasks"."id"
          UPDATE_SQL
        )
      end
    end

    change_column_null :tasks_tasking_plans, :closes_at_ntz, false
  end
end
