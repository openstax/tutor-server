class Research::ManipulateStudentTask

  lev_routine

  def exec(hook:, task:, task_step: nil)
    task.research_study_brains.each do |brain|
      next unless brain.hook.blank? || brain.hook.to_sym == hook.to_sym
      error = brain.evaluate(binding())
      fatal_error(code: :invalid_research_code, message: error.to_s) if error.present?
    end
  end

end
