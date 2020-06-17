class CachePointsForExistingTasks < ActiveRecord::Migration[5.2]
  def up
    Tasks::Models::Task.preload(
       :course, :taskings, :time_zone, task_steps: :tasked, task_plan: [
         :tasking_plans, :dropped_questions, :grading_template, :extensions
       ]
    ).find_in_batches do |tasks|
      tasks.each do |task|
        task.available_points = task.available_points(use_cache: false)
        task.published_points_before_due = task.published_points(
          past_due: false, use_cache: false
        ) || Float::NAN
        task.published_points_after_due = task.published_points(
          past_due: true, use_cache: false
        ) || Float::NAN
        task.is_provisional_score_before_due = task.provisional_score?(
          past_due: false, use_cache: false
        )
        task.is_provisional_score_after_due = task.provisional_score?(
          past_due: true, use_cache: false
        )
      end

      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ],
        columns: [
          :available_points,
          :published_points_before_due,
          :published_points_after_due,
          :is_provisional_score_before_due,
          :is_provisional_score_after_due
        ]
      }
    end

    change_column_default :tasks_tasks, :available_points, 0.0
    change_column_default :tasks_tasks, :published_points_before_due, Float::NAN
    change_column_default :tasks_tasks, :published_points_after_due, Float::NAN
    change_column_default :tasks_tasks, :is_provisional_score_before_due, false
    change_column_default :tasks_tasks, :is_provisional_score_after_due, false

    change_column_null :tasks_tasks, :available_points, false
    change_column_null :tasks_tasks, :published_points_before_due, false
    change_column_null :tasks_tasks, :published_points_after_due, false
    change_column_null :tasks_tasks, :is_provisional_score_before_due, false
    change_column_null :tasks_tasks, :is_provisional_score_after_due, false
  end

  def down
    change_column_null :tasks_tasks, :is_provisional_score_after_due, true
    change_column_null :tasks_tasks, :is_provisional_score_before_due, true
    change_column_null :tasks_tasks, :published_points_after_due, true
    change_column_null :tasks_tasks, :published_points_before_due, true
    change_column_null :tasks_tasks, :available_points, true

    change_column_default :tasks_tasks, :is_provisional_score_after_due, nil
    change_column_default :tasks_tasks, :is_provisional_score_before_due, nil
    change_column_default :tasks_tasks, :published_points_after_due, nil
    change_column_default :tasks_tasks, :published_points_before_due, nil
    change_column_default :tasks_tasks, :available_points, nil
  end
end
