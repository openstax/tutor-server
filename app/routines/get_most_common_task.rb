# Returns the most common task from an array of tasks
# Used to display headings in scores and gradebook
class GetMostCommonTask
  lev_routine express_output: :task

  def exec(tasks:)
    no_placeholder_tasks = tasks.select { |task| task.placeholder_steps_count == 0 }

    representative_tasks = no_placeholder_tasks.empty? ? tasks : no_placeholder_tasks

    most_common_tasks = representative_tasks.group_by(
      &:actual_and_placeholder_exercise_count
    ).max_by { |_, tasks| tasks.size }.second

    outputs.task = most_common_tasks.first
  end
end
