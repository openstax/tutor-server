class CcDashboardAnswerTimes < ActiveRecord::Migration

    def up
      execute <<-EOS
      create materialized view cc_section_last_completion_time as

      select
        course_membership_periods.id as course_period_id
        ,tasks_concept_coach_tasks.content_page_id as content_page_id
        ,max(tasks_task_steps.last_completed_at) AS task_steps_last_completed_at
        ,array_agg(tasks_tasks.id) as task_ids
      from
        tasks_concept_coach_tasks
      join tasks_tasks on tasks_tasks.id = tasks_concept_coach_tasks.tasks_task_id
        and tasks_tasks.deleted_at is null
      join tasks_task_steps on tasks_task_steps.tasks_task_id = tasks_tasks.id
        and tasks_task_steps.tasked_type = 'Tasks::Models::TaskedExercise'
      join tasks_taskings on tasks_taskings.tasks_task_id = tasks_tasks.id
        and tasks_taskings.deleted_at is null
      join course_membership_periods on course_membership_periods.id = tasks_taskings.course_membership_period_id
        and course_membership_periods.deleted_at is null
      where
        tasks_concept_coach_tasks.deleted_at is null
        and tasks_tasks.completed_exercise_steps_count > 0
      group by
        course_membership_periods.id
        ,tasks_concept_coach_tasks.content_page_id

      EOS

      # refresh concurrently requires a unique index
      execute "create unique index cc_last_completion_time_page_indx on cc_section_last_completion_time(course_period_id, content_page_id)"

      execute "create index cc_last_completion_time_period_indx on cc_section_last_completion_time(course_period_id)"
    end

    def down
      execute "drop materialized view cc_section_last_completion_time"
    end

end
