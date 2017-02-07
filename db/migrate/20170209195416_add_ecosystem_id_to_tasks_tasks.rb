class AddEcosystemIdToTasksTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :content_ecosystem_id, :integer

    # Tasks that come from TaskPlans
    Tasks::Models::Task.joins(:task_plan).preload(task_plan: :ecosystem).find_each do |task|
      task.update_attribute :ecosystem, task.task_plan.ecosystem
    end

    # CC tasks
    Tasks::Models::Task.joins(:concept_coach_task)
                       .preload(concept_coach_task: { page: :ecosystem })
                       .find_each do |task|
      task.update_attribute :ecosystem, task.concept_coach_task.page.ecosystem
    end

    # Practice tasks
    Tasks::Models::Task.where(content_ecosystem_id: nil).find_in_batches do |tasks|
      task_id_to_core_page_ids_map = GetTaskCorePageIds[tasks: tasks]

      tasks.each do |task|
        core_page_ids = task_id_to_core_page_ids_map[task.id]
        ecosystem = Content::Ecosystem.find_by_page_ids(*core_page_ids)
        task.update_attribute :ecosystem, ecosystem
      end
    end

    # In case we missed anyone for weird reasons,
    # allow the migration to finish and we can fix them later
    Tasks::Models::Task.where(content_ecosystem_id: nil).update_all(content_ecosystem_id: -1)

    change_column_null :tasks_tasks, :content_ecosystem_id, false
    add_index :tasks_tasks, :content_ecosystem_id
  end
end
