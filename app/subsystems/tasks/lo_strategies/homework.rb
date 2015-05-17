class Tasks::LoStrategies::Homework

  def los(task:)
    raise "expected task to be a Homework but got #{task.task_type} instead" \
      unless task.homework?

    urls = task.task_steps.select{|task_step| task_step.exercise?}.
                           collect{|task_step| task_step.tasked.url}.
                           uniq

    exercise_los = Content::Models::Tag.joins{exercise_tags.exercise}
                                       .where{exercise_tags.exercise.url.in urls}
                                       .select{|tag| tag.lo?}
                                       .collect{|tag| tag.value}

    pages = Content::Routines::SearchPages[tag: exercise_los, match_count: 1]
    los = Content::GetLos[page_ids: pages.map(&:id)]

    los
  end

end
