desc 'Temporary rake task to be used if any task_plans conflict with the latest migration'
task :migrate_task_plans => :environment do |tt, args|
  # Find invalid task_plans and assign an ecosystem to them
  Tasks::Models::TaskPlan.transaction do
    Tasks::Models::TaskPlan.lock.where(content_ecosystem_id: nil).each do |task_plan|
      owner = task_plan.owner
      # If owner is not a course, abort
      raise 'TaskPlan with no ecosystem and no course found' unless owner.is_a?(Entity::Course)

      ecosystem = GetCourseEcosystem.call(course: owner)
      # If the course has no ecosystems, abort
      raise 'TaskPlan found for a course with no ecosystem' if ecosystem.nil?

      task_plan.update_column(:content_ecosystem_id, ecosystem.id)
    end
  end

  # Invalid records are gone, so run the migration now
  Rake::Task[:"db:migrate"].invoke
end
