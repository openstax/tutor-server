class Research::ModifiedTask

  lev_routine express_output: :task

  def exec(task:)
    outputs.task = task
    task.research_study_brains.each do |brain|
      next unless brain.should_execute? :modified_task
      task.research_cohorts.each do |cohort|
        outputs.merge(
          brain.modified_task(cohort: cohort, task: outputs.task) || {}
        )
      end
    end
  end

end
