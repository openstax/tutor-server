class Research::ManipulateStudentTask

  lev_routine

  def exec(task:, activity: nil)

    task.research_cohorts.includes(:brains).each do |cohort|
      cohort.brains.each do |brain|
        brain.evaluate(binding()) if brain.student_task?
      end
    end
  end

end
