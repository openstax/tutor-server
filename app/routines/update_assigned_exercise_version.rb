class UpdateAssignedExerciseVersion
  lev_routine

  protected

  def exec(number:, profile:)
    updated_task_plan_ids = []
    updated_tasked_exercise_ids = []

    all_versions = Content::Models::Exercise.where(number: number)
    new_version  = all_versions.max_by(&:version)
    old_ids      = all_versions.without(new_version).map {|v| v.id.to_s }
    update_ids   = Content::Models::Exercise
                     .joins(tasked_exercises: { task_step: { task: :task_plan } })
                     .where(number: number)
                     .where.not(version: new_version.version)
                     .pluck('tasks_task_plans.id', 'tasks_tasked_exercises.id')

    taskeds_by_plan_id = Hash.new {|hash, key| hash[key] = [] }
    update_ids.each {|set| taskeds_by_plan_id[set[0]] << set[1] }

    taskeds_by_plan_id.each do |plan_id, tasked_ids|
      plan = Tasks::Models::TaskPlan.find(plan_id)
      next if plan.out_to_students?

      plan.settings['exercises'].each {|ex| ex['id'] = new_version.id.to_s if ex['id'].in?(old_ids) }
      plan.settings['page_ids'] << new_version.page.id.to_s
      plan.settings['page_ids'].uniq!
      plan.save

      Tasks::Models::TaskedExercise.where(id: tasked_ids).update_all(content_exercise_id: new_version.id)

      updated_task_plan_ids << plan.id
      updated_tasked_exercise_ids << tasked_ids
    end

    outputs.updated_task_plan_ids = updated_task_plan_ids
    outputs.updated_tasked_exercise_ids = updated_tasked_exercise_ids.flatten
    outputs.content_exercise_ids = all_versions.map(&:id)
  end
end
