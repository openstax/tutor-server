class Research::UpdateStudentTasked

  lev_routine express_output: :tasked

  def exec(tasked:)
    outputs.tasked = tasked

    tasked.task_step.task.research_study_brains.each do |brain|
      next unless brain.should_execute? :update_student_tasked

      outputs.merge!(
        brain.update_student_tasked(tasked: tasked)
      )
    end
  end

end
