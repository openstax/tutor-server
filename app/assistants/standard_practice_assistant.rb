class StandardPracticeAssistant < AbstractAssistant

  def task_plan_due(task_plan)
    task = run(:create_task, task_plan: task_plan).outputs[:task]
    task_plan.assignees.each do |a|
      run(:assign_task, task: task, assignee: a)
    end
  end

  def task_updated(task)
  end

  def task_completed(task)
  end

  def can_participate?(klass)
    true
  end

  def generate_educator_report(klass)
    ''
  end

  def generate_study_report(klass)
    ''
  end

end
