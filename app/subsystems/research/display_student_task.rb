class Research::DisplayStudentTask

  lev_routine express_output: :task

  def exec(task:)
    outputs.task = task

    task.research_study_brains.each do |brain|
      next unless brain.should_execute? :display_student_task

      outputs.merge(
        brain.task_for_display(task: outputs.task)
      )
    end

  end

end
