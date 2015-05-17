class Tasks::LoStrategies::IReading

  def los(task:)
    raise "expected task to be a Reading but got #{task.task_type} instead" \
      unless task.reading?

    page_ids = task.task_plan.settings['page_ids']
    los = Content::GetLos[page_ids: page_ids]
    los
  end

end
