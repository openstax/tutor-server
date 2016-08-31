class AssignGroupTypesToDefaultGroupSteps < ActiveRecord::Migration
  PERSONALIZED_TASK_TYPES = Tasks::Models::Task.task_types.values_at(:homework, :reading)
  PRACTICE_TASK_TYPES = Tasks::Models::Task.task_types.values_at(
    :page_practice, :chapter_practice, :mixed_practice
  )

  DEFAULT_STEP_GROUP = Tasks::Models::TaskStep.group_types[:default_group]
  PERSONALIZED_STEP_GROUP = Tasks::Models::TaskStep.group_types[:personalized_group]

  def up
    task_steps = Tasks::Models::TaskStep.default_group
                                        .joins(:task)
                                        .where(task: {task_type: PERSONALIZED_TASK_TYPES})
                                        .preload(task: :task_steps)

    task_steps.find_each do |task_step|
      begin
        previous_step = task_step.previous_by_number
      end while previous_step.present? && previous_step.default_group?

      next if previous_step.nil?

      task_step.update_attributes(group_type: previous_step.group_type,
                                  related_content: previous_step.related_content,
                                  labels: previous_step.labels)
    end

    Tasks::Models::TaskStep.default_group
                           .joins(:task)
                           .where(task: {task_type: PRACTICE_TASK_TYPES})
                           .update_all(group_type: PERSONALIZED_STEP_GROUP)
  end

  def down
    Tasks::Models::TaskStep.default_group
                           .joins(:task)
                           .where(task: {task_type: PRACTICE_TASK_TYPES})
                           .update_all(group_type: DEFAULT_STEP_GROUP)
  end
end
