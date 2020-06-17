class CachePointsForExistingTasks < ActiveRecord::Migration[5.2]
  def up
    Tasks::Models::Task.preload(
       :course, :taskings, :time_zone, task_steps: :tasked, task_plan: [
         :tasking_plans, :dropped_questions, :grading_template, :extensions
       ]
    ).find_in_batches do |tasks|
      tasks.each do |task|
        task.available_points = task.available_points(use_cache: false)
        task.published_points_without_auto_grading_feedback = task.published_points(
          auto_grading_feedback_available: false, use_cache: false
        ) || Float::NAN
        task.published_points_with_auto_grading_feedback = task.published_points(
          auto_grading_feedback_available: true, use_cache: false
        ) || Float::NAN
        task.is_provisional_score_without_auto_grading_feedback = task.provisional_score?(
          auto_grading_feedback_available: false, use_cache: false
        )
        task.is_provisional_score_with_auto_grading_feedback = task.provisional_score?(
          auto_grading_feedback_available: true, use_cache: false
        )
      end

      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ],
        columns: [
          :available_points,
          :published_points_without_auto_grading_feedback,
          :published_points_with_auto_grading_feedback,
          :is_provisional_score_without_auto_grading_feedback,
          :is_provisional_score_with_auto_grading_feedback
        ]
      }
    end

    change_column_default :tasks_tasks, :available_points, 0.0
    change_column_default :tasks_tasks, :published_points_without_auto_grading_feedback, Float::NAN
    change_column_default :tasks_tasks, :published_points_with_auto_grading_feedback, Float::NAN
    change_column_default :tasks_tasks, :is_provisional_score_without_auto_grading_feedback, false
    change_column_default :tasks_tasks, :is_provisional_score_with_auto_grading_feedback, false

    change_column_null :tasks_tasks, :available_points, false
    change_column_null :tasks_tasks, :published_points_without_auto_grading_feedback, false
    change_column_null :tasks_tasks, :published_points_with_auto_grading_feedback, false
    change_column_null :tasks_tasks, :is_provisional_score_without_auto_grading_feedback, false
    change_column_null :tasks_tasks, :is_provisional_score_with_auto_grading_feedback, false
  end

  def down
    change_column_null :tasks_tasks, :is_provisional_score_with_auto_grading_feedback, true
    change_column_null :tasks_tasks, :is_provisional_score_without_auto_grading_feedback, true
    change_column_null :tasks_tasks, :published_points_with_auto_grading_feedback, true
    change_column_null :tasks_tasks, :published_points_without_auto_grading_feedback, true
    change_column_null :tasks_tasks, :available_points, true

    change_column_default :tasks_tasks, :is_provisional_score_with_auto_grading_feedback, nil
    change_column_default :tasks_tasks, :is_provisional_score_without_auto_grading_feedback, nil
    change_column_default :tasks_tasks, :published_points_with_auto_grading_feedback, nil
    change_column_default :tasks_tasks, :published_points_without_auto_grading_feedback, nil
    change_column_default :tasks_tasks, :available_points, nil
  end
end
