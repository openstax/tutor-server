class Research::ManipulateStudentTask

  lev_routine

  def exec(task:, hook:)
    task.research_study_brains.each do |brain|
      next unless brain.hook.blank? || brain.hook == hook
      brain.evaluate(binding())
    end
  end

end
