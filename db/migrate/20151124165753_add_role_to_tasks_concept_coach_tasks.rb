class AddRoleToTasksConceptCoachTasks < ActiveRecord::Migration[4.2]
  def change
    add_reference :tasks_concept_coach_tasks, :entity_role,
                  foreign_key: { on_update: :cascade, on_delete: :cascade }

    reversible do |direction|
      direction.up do
        Tasks::Models::ConceptCoachTask.unscoped.find_each do |cc_task|
          cc_task.role = cc_task.task.taskings.first.role
          cc_task.save!
        end

        change_column_null :tasks_concept_coach_tasks, :entity_role_id, false
      end
    end

    add_index :tasks_concept_coach_tasks, [:entity_role_id, :content_page_id],
              unique: true, name: 'index_tasks_concept_coach_tasks_on_e_r_id_and_c_p_id'
  end
end
