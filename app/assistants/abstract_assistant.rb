class AbstractAssistant

  def task_plan_due(task_plan)
    raise NotYetImplemented
  end

  def task_updated(task)
    raise NotYetImplemented
  end

  def task_completed(task)
    raise NotYetImplemented
  end

  def can_participate?(klass)
    raise NotYetImplemented
  end

  def generate_educator_report(klass)
    raise NotYetImplemented
  end

  def generate_study_report(klass)
    raise NotYetImplemented
  end

end
