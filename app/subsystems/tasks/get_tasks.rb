require_relative 'models/entity_extensions'

class Tasks::GetTasks
  lev_routine express_output: :tasks

  include VerifyAndGetIdArray

  protected

  def exec(roles:)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    entity_tasks = Tasks::Models::Tasking.
                     where{entity_role_id.in role_ids}.
                     collect{|tasking| tasking.task}

    # This was temporarily removed due to a problem (with entity_extensions?):
    # outputs[:tasks] = Entity::Task.joins{taskings}
    #                               .where{taskings.entity_role_id.in role_ids}

    outputs[:tasks] = entity_tasks
  end

end
