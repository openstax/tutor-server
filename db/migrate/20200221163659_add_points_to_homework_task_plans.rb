class AddPointsToHomeworkTaskPlans < ActiveRecord::Migration[5.2]
  def up
    Tasks::Models::TaskPlan.reset_column_information
    Tasks::Models::TaskPlan.where(type: 'homework').find_in_batches do |task_plans|
      task_plans.each do |task_plan|
        task_plan.settings['exercises'] = task_plan.settings['exercise_ids'].map do |id|
          { 'id' => id.to_s, 'points' => [ 1 ] }
        end
        task_plan.settings.delete 'exercise_ids'
      end

      Tasks::Models::TaskPlan.import task_plans, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ], columns: [ :settings ]
      }
    end
  end

  def down
    Tasks::Models::TaskPlan.reset_column_information
    Tasks::Models::TaskPlan.where(type: 'homework').find_in_batches do |task_plans|
      task_plans.each do |task_plan|
        task_plan.settings['exercise_ids'] = task_plan.settings['exercises'].map do |exercise|
          exercise['id']
        end
        task_plan.settings.delete 'exercises'
      end

      Tasks::Models::TaskPlan.import task_plans, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ], columns: [ :settings ]
      }
    end
  end
end
