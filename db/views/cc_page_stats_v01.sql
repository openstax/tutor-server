select
  tasks_concept_coach_tasks.content_page_id as coach_task_content_page_id
  ,course_membership_periods.course_profile_course_id as course_id
  ,course_membership_periods.id as course_period_id
  ,tasks_task_steps.group_type
  ,count(tasks_task_steps) AS steps_count
  ,max(tasks_task_steps.last_completed_at) as task_steps_last_completed_at
  ,count(tasks_task_steps.first_completed_at) as completed_count
  ,count(tasks_task_steps.first_completed_at) filter (
    where tasks_tasked_exercises.answer_id = tasks_tasked_exercises.correct_answer_id
  ) AS correct_count
  ,array_agg(distinct(tasks_taskings.entity_role_id)) as role_ids
  ,array_agg(distinct(tasks_tasks.id)) as task_ids
from
  tasks_concept_coach_tasks
join tasks_tasks on tasks_tasks.id = tasks_concept_coach_tasks.tasks_task_id
  and tasks_tasks.deleted_at is null
  and tasks_tasks.completed_exercise_steps_count > 0
join tasks_task_steps on tasks_task_steps.tasks_task_id = tasks_tasks.id
  and tasks_task_steps.tasked_type = 'Tasks::Models::TaskedExercise'
join tasks_tasked_exercises on tasks_task_steps.tasked_id = tasks_tasked_exercises.id
join tasks_taskings on tasks_taskings.tasks_task_id = tasks_tasks.id
  and tasks_taskings.deleted_at is null
join course_membership_periods on course_membership_periods.id = tasks_taskings.course_membership_period_id
  and course_membership_periods.deleted_at is null
where
  tasks_concept_coach_tasks.deleted_at is null
group by
  course_id
  ,course_period_id
  ,tasks_concept_coach_tasks.content_page_id
  ,tasks_task_steps.group_type
