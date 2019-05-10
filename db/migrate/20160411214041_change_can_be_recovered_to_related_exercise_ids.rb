class ChangeCanBeRecoveredToRelatedExerciseIds < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_steps, :related_exercise_ids, :integer, array: true,
                                                         null: false, default: []

    reversible do |dir|
      dir.up do
        related_exercise_ids_map = {}

        Tasks::Models::TaskedExercise.unscoped.preload(
          [:task_step, {exercise: {page: :reading_context_pool}}]
        ).where(can_be_recovered: true).find_each do |te|
          next if te.task_step.nil?

          exercise = te.exercise

          related_exercise_ids = related_exercise_ids_map[exercise.id]

          if related_exercise_ids.nil?
            pool_exercises = exercise.page.reading_context_pool.exercises.to_a

            los = exercise.los
            aplos = exercise.aplos

            # For the original Try Another,
            # we allow only exercises that share at least one LO or APLO with the original exercise
            related_exercise_ids = pool_exercises.select do |ex|
              ex.los.any?{ |lo| los.include?(lo) } || ex.aplos.any?{ |aplo| aplos.include?(aplo) }
            end.map(&:id)

            related_exercise_ids_map[exercise.id] = related_exercise_ids
          end

          te.task_step.update_attribute :related_exercise_ids, related_exercise_ids
        end
      end

      dir.down do
        Tasks::Models::TaskedExercise.unscoped.preload(:task_step).select do |te|
          te.task_step.related_exercise_ids.any?
        end.each do |te|
          te.update_attribute :can_be_recovered, true
        end
      end
    end

    remove_column :tasks_tasked_exercises, :can_be_recovered, :boolean, null: false,
                                                                        default: false
  end
end
