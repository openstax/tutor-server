require_relative 'models/entity_extensions'

class Tasks::GetTasks
  lev_routine express_output: :tasks

  include VerifyAndGetIdArray

  protected

  def exec(roles:)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    outputs[:tasks] = Entity::Task.joins{taskings}
                                  .where{taskings.entity_role_id.in role_ids}
  end

end
