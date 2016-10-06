class GetTaskCorePageIds

  lev_routine express_output: :task_id_to_core_page_ids_map

  protected

  # The core page ids exclude spaced practice/personalized pages
  def exec(tasks:)
    tasks_by_type = tasks.group_by{ |task| task.task_type.to_sym }

    task_id_to_core_page_ids_map = {}

    # Get core page ids for homework tasks
    unless tasks_by_type[:homework].blank?
      homework_task_ids = tasks_by_type[:homework].map(&:id)
      homework_exercise_id_to_task_ids_map = {}
      Tasks::Models::TaskPlan.joins(:tasks)
                             .where(type: 'homework', tasks: {id: homework_task_ids})
                             .select([Tasks::Models::Task.arel_table[:id].as('task_id'), :settings])
                             .each do |task_plan|
        exercise_ids = (task_plan.settings['exercise_ids'] || []).compact.map(&:to_i)
        exercise_ids.each do |exercise_id|
          homework_exercise_id_to_task_ids_map[exercise_id] ||= []
          homework_exercise_id_to_task_ids_map[exercise_id] << task_plan.task_id
        end
      end

      homework_exercise_ids = homework_exercise_id_to_task_ids_map.keys.flatten
      Content::Models::Exercise.where(id: homework_exercise_ids)
                               .pluck(:id, :content_page_id)
                               .each do |exercise_id, content_page_id|
        task_ids = homework_exercise_id_to_task_ids_map[exercise_id]

        task_ids.each do |task_id|
          task_id_to_core_page_ids_map[task_id] ||= []
          task_id_to_core_page_ids_map[task_id] << content_page_id
        end
      end

      task_id_to_core_page_ids_map.each do |task_id, core_page_ids|
        task_id_to_core_page_ids_map[task_id] = core_page_ids.uniq
      end
    end

    # Get core page ids for reading tasks
    unless tasks_by_type[:reading].blank?
      reading_task_ids = tasks_by_type[:reading].map(&:id)
      Tasks::Models::TaskPlan.joins(:tasks)
                             .where(type: 'reading', tasks: {id: reading_task_ids})
                             .select([Tasks::Models::Task.arel_table[:id].as('task_id'), :settings])
                             .each do |task_plan|
        page_ids = (task_plan.settings['page_ids'] || []).compact.map(&:to_i).uniq

        task_id_to_core_page_ids_map[task_plan.task_id] = page_ids
      end
    end

    # Get core page ids for Concept Coach tasks
    unless tasks_by_type[:concept_coach].blank?
      cc_task_ids = tasks_by_type[:concept_coach].map(&:id)
      Tasks::Models::ConceptCoachTask.joins(:task)
                                     .where(task: {id: cc_task_ids})
                                     .pluck(:tasks_task_id, :content_page_id)
                                     .each do |task_id, page_id|
        task_id_to_core_page_ids_map[task_id] = [page_id]
      end
    end

    # Get core page ids for all other tasks
    other_task_ids = tasks_by_type.except(:reading, :homework, :concept_coach)
                                  .values.flatten.map(&:id)

    if other_task_ids.any?
      Tasks::Models::TaskedExercise.joins([:task_step, :exercise])
                                   .where(task_step: {tasks_task_id: other_task_ids})
                                   .select([Tasks::Models::TaskStep.arel_table[:tasks_task_id],
                                            Content::Models::Exercise.arel_table[:content_page_id]])
                                   .group_by(&:tasks_task_id)
                                   .each do |task_id, tasked_exercises|
        task_id_to_core_page_ids_map[task_id] = tasked_exercises.map(&:content_page_id).uniq.sort
      end
    end

    outputs.task_id_to_core_page_ids_map = task_id_to_core_page_ids_map
  end
end
