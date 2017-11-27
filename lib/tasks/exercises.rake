require 'values_table'

namespace :exercises do
  desc 'Removes defective exercises from student assignments'
  task remove: :environment do |task, args|
    uids = args.extras
    fail 'You must provide one or more exercise number@version to remove' if uids.empty?

    split_values = uids.map { |value| value.split('@') }
                       .reject{ |number, version| version.nil? }
                       .map { |number, version| [ number.to_i, version.to_i ] }

    exercises_join_query = <<-JOIN_SQL
      INNER JOIN (#{ValuesTable.new(split_values)})
        AS "ex" ("number", "version")
        ON "content_exercises"."number" = "ex"."number"
          AND "content_exercises"."version" = "ex"."version"
    JOIN_SQL

    Tasks::Models::Task.transaction do
      tasked_exercises = Tasks::Models::TaskedExercise
        .select(:id)
        .joins(:exercise)
        .joins(exercises_join_query)
      tasked_exercise_ids = tasked_exercises.map(&:id)

      task_steps = Tasks::Models::TaskStep
        .select([ :id, :tasks_task_id ])
        .where(tasked_type: Tasks::Models::TaskedExercise.name, tasked_id: tasked_exercise_ids)
      task_ids = task_steps.map(&:tasks_task_id)

      task_steps.delete_all
      tasked_exercises.delete_all

      # Recalculate scores and caches
      Tasks::Models::Task.where(id: task_ids).preload(:task_steps).each(&:touch)
    end
  end
end
