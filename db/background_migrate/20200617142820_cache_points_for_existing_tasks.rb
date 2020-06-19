class CachePointsForExistingTasks < ActiveRecord::Migration[5.2]
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  def up
    loop do
      num_tasks = Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task.where(available_points: nil)
                                   .order(created_at: :desc)
                                   .limit(BATCH_SIZE)
                                   .preload(
           :course, :taskings, :time_zone, task_steps: :tasked, task_plan: [
             :tasking_plans, :dropped_questions, :grading_template, :extensions
           ]
        ).to_a
        next 0 if tasks.empty?

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
          task.gradable_step_count = 0
        end

        Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
          conflict_target: [ :id ],
          columns: [
            :available_points,
            :published_points_before_due,
            :published_points_after_due,
            :is_provisional_score_before_due,
            :is_provisional_score_after_due,
            :gradable_step_count
          ]
        }

        tasks.size
      end

      break if num_tasks < BATCH_SIZE
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
    change_column_null :tasks_tasks, :gradable_step_count, false
  end

  def down
    change_column_null :tasks_tasks, :gradable_step_count, true
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
