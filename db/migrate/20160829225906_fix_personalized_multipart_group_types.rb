class FixPersonalizedMultipartGroupTypes < ActiveRecord::Migration
  def up
    task_types = Tasks::Models::Task.task_types.values_at(:homework, :reading)

    task_steps = Tasks::Models::TaskStep.default_group.joins(:task)
                                        .where(task: {task_type: task_types})
                                        .preload(task: :task_steps)

    task_steps.find_each do |task_step|
      begin
        previous_step = task_step.previous_by_number
      end while previous_step.present? && previous_step.group_type == 'default_group'

      next if previous_step.nil?

      task_step.update_attributes(group_type: previous_step.group_type,
                                  related_content: previous_step.related_content,
                                  labels: previous_step.labels)
    end
  end

  def down
  end
end
